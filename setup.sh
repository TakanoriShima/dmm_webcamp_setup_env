#!/bin/bash

# 結果を格納する変数を初期化
installation_results=""

# swap領域 を拡張
if ! swapon --show | grep -q '/var/swap.1'; then
  sudo dd if=/dev/zero of=/var/swap.1 bs=1M count=1024
  sudo chmod 600 /var/swap.1
  sudo mkswap /var/swap.1
  sudo swapon /var/swap.1
  sudo sh -c "echo '/var/swap.1 swap swap defaults 0 0' >> /etc/fstab"
fi

# パッケージ情報の更新
sudo yum update -y
if [ $? -ne 0 ]; then installation_results+="パッケージ情報の更新が失敗しました。\n"; fi

# 必要なツールとライブラリのインストール
sudo yum install -y git bzip2 gcc openssl-devel readline-devel zlib-devel libffi-devel
if [ $? -ne 0 ]; then installation_results+="必要なツールとライブラリのインストールが失敗しました。\n"; fi

# 開発ツールのインストール（主要な開発ライブラリを含む）
sudo yum groupinstall -y "Development Tools"
if [ $? -ne 0 ]; then installation_results+="開発ツールのインストールが失敗しました。\n"; fi

# rbenv のインストール
if [ ! -d "$HOME/.rbenv" ]; then
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
  echo 'eval "$(rbenv init -)"' >> ~/.bashrc
  source ~/.bashrc
fi
if [ $? -ne 0 ]; then installation_results+="rbenvのインストールが失敗しました。\n"; fi

# ruby-build のインストール
if [ ! -d "$HOME/.rbenv/plugins/ruby-build" ]; then
  git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
fi
if [ $? -ne 0 ];then installation_results+="ruby-buildのインストールが失敗しました。\n"; fi

# Ruby 3.1.2 のインストール
if ! rbenv versions | grep -q '3.1.2'; then
  rbenv install 3.1.2
fi
rbenv global 3.1.2
if [ $? -ne 0 ]; then installation_results+="Ruby 3.1.2のインストールが失敗しました。\n"; fi

# Nokogiri のインストール
gem install nokogiri -v 1.16.6 -- --use-system-libraries
if [ $? -ne 0 ]; then installation_results+="Nokogiriのインストールが失敗しました。\n"; fi

# Rails 6.1.4 のインストール
gem install rails -v 6.1.4
if [ $? -ne 0 ]; then installation_results+="Rails 6.1.4のインストールが失敗しました。\n"; fi

# Node.js 18.x のソースコードをダウンロード
NODE_VERSION="v18.17.1"
curl -o node-${NODE_VERSION}.tar.gz https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}.tar.gz
if [ $? -ne 0 ]; then installation_results+="Node.js ソースコードのダウンロードが失敗しました。\n"; fi

# ソースコードの展開
tar -xzf node-${NODE_VERSION}.tar.gz
if [ $? -ne 0 ]; then installation_results+="Node.js ソースコードの展開が失敗しました。\n"; fi

# Node.js のビルドとインストール
cd node-${NODE_VERSION}
./configure
if [ $? -ne 0 ]; then installation_results+="Node.js の構成が失敗しました。\n"; fi

make -j$(nproc)
if [ $? -ne 0 ]; then installation_results+="Node.js のビルドが失敗しました。\n"; fi

sudo make install
if [ $? -ne 0 ]; then installation_results+="Node.js のインストールが失敗しました。\n"; fi

# Node.js と npm のインストール確認
if ! command -v node > /dev/null; then
  installation_results+="Node.js が正しくインストールされていません。\n"
fi

if ! command -v npm > /dev/null; then
  installation_results+="npm が正しくインストールされていません。\n"
fi

# Yarn のインストール
sudo npm install --global yarn
if [ $? -ne 0 ]; then installation_results+="Yarnのインストールが失敗しました。\n"; fi

# PHP 8.2 のインストール
sudo amazon-linux-extras enable php8.2
sudo yum install -y php-cli php-pdo php-mbstring php-mysqlnd php-json php-gd php-openssl php-curl php-xml php-intl 
if [ $? -ne 0 ]; then installation_results+="PHP 8.2のインストールが失敗しました。\n"; fi

# composer のインストール
if ! command -v composer > /dev/null; then
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
  php composer-setup.php
  php -r "unlink('composer-setup.php');"
  sudo mv composer.phar /usr/local/bin/composer
fi
if [ $? -ne 0 ]; then installation_results+="Composerのインストールが失敗しました。\n"; fi

# MariaDB のインストール
sudo amazon-linux-extras enable mariadb10.5
sudo yum -y install mariadb
if [ $? -ne 0 ]; then installation_results+="MariaDBのインストールが失敗しました。\n"; fi

# ターミナルのプロンプト表示設定
PROMPT_SCRIPT="/home/ec2-user/prompt.sh"
if [ ! -f "$PROMPT_SCRIPT" ]; then
  echo '#!/bin/sh' > $PROMPT_SCRIPT
  echo 'parse_git_branch() {' >> $PROMPT_SCRIPT
  echo '    git branch 2> /dev/null | sed -e '\''/^[^*]/d'\'' -e '\''s/* \(.*\)/ (\1)/'\''' >> $PROMPT_SCRIPT
  echo '}' >> $PROMPT_SCRIPT
  echo 'export PS1="\[\033[01;32m\]\u\[\033[00m\]:\[\033[34m\]\w\[\033[00m\]\$(parse_git_branch) $ "' >> $PROMPT_SCRIPT

  sudo chmod 755 $PROMPT_SCRIPT
  echo 'source ~/prompt.sh' >> /home/ec2-user/.bashrc
  echo 'source ~/prompt.sh' >> /home/ec2-user/.bash_profile
fi
if [ $? -ne 0 ]; then installation_results+="プロンプト設定が失敗しました。\n"; fi

# シェルの設定を再読み込み
source ~/.bashrc
source ~/.bash_profile

# クリーンアップ
cd ..
rm -rf node-${NODE_VERSION} node-${NODE_VERSION}.tar.gz
sudo yum clean all
if [ $? -ne 0 ]; then installation_results+="クリーンアップが失敗しました。\n"; fi

# 結果の表示
if [ -z "$installation_results" ]; then
  echo "すべてのライブラリが正常にインストールされました。環境構築が完了しました。"
else
  echo -e "$installation_results"
fi

