#!/bin/bash

# 結果を格納する変数を初期化
installation_results=""

# パッケージ情報の更新
sudo yum update -y
if [ $? -ne 0 ]; then installation_results+="パッケージ情報の更新が失敗しました。\n"; fi

# 必要なツールとライブラリのインストール
sudo yum install -y git curl bzip2 gcc gcc-c++ make openssl-devel readline-devel zlib-devel libffi-devel
if [ $? -ne 0 ]; then installation_results+="必要なツールとライブラリのインストールが失敗しました。\n"; fi

# NVMのインストール
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
if [ $? -ne 0 ]; then installation_results+="NVMのインストールが失敗しました。\n"; fi

# NVMを使用できるようにするための設定
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # NVMの初期化
echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc

# NVMを使用してNode.js 18をソースからビルド
nvm install 18 --build-from-source
if [ $? -ne 0 ]; then installation_results+="Node.js 18のソースビルドが失敗しました。\n"; fi

# Rubyのインストール (rbenvを使用)
if [ ! -d "$HOME/.rbenv" ]; then
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
  echo 'eval "$(rbenv init -)"' >> ~/.bashrc
  source ~/.bashrc

  # ruby-buildのインストール
  git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
fi
if [ $? -ne 0 ]; then installation_results+="rbenvのインストールが失敗しました。\n"; fi

# Ruby 3.1.2 のインストール
if ! rbenv versions | grep -q '3.1.2'; then
  rbenv install 3.1.2
  rbenv global 3.1.2
fi
if [ $? -ne 0 ]; then installation_results+="Ruby 3.1.2のインストールが失敗しました。\n"; fi

# Rails 6.1.4 のインストール
gem install rails -v 6.1.4
if [ $? -ne 0 ]; then installation_results+="Rails 6.1.4のインストールが失敗しました。\n"; fi

# Nokogiri のインストール
gem install nokogiri -v 1.16.6 -- --use-system-libraries
if [ $? -ne 0 ]; then installation_results+="Nokogiriのインストールが失敗しました。\n"; fi

# Composer のインストール
if ! command -v composer > /dev/null; then
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
  php composer-setup.php
  php -r "unlink('composer-setup.php');"
  sudo mv composer.phar /usr/local/bin/composer
fi
if [ $? -ne 0 ]; then installation_results+="Composerのインストールが失敗しました。\n"; fi

# PHP 8.2 のインストール
sudo amazon-linux-extras enable php8.2
sudo yum install -y php-cli php-pdo php-mbstring php-mysqlnd php-json php-gd php-openssl php-curl php-xml php-intl 
if [ $? -ne 0 ]; then installation_results+="PHP 8.2のインストールが失敗しました。\n"; fi

# 結果の表示
if [ -z "$installation_results" ]; then
  echo "すべてのライブラリが正常にインストールされました。環境構築が完了しました。"
else
  echo -e "$installation_results"
fi

