#!/bin/bash

# 環境変数の設定
RUBY_VERSION="3.1.2"
RAILS_VERSION="6.1.4"
NODE_VERSION="v18.18.2"
NODE_DIR="/usr/local/share/node"
PHP_VERSION="8.2"
MARIADB_VERSION="10.5"

# 結果を格納する変数を初期化
installation_results=""

# パッケージ情報の更新
sudo yum update -y
if [ $? -ne 0 ]; then installation_results+="パッケージ情報の更新が失敗しました。\n"; fi

# 必要なツールとライブラリのインストール
sudo yum install -y git curl bzip2 gcc gcc-c++ make openssl-devel readline-devel zlib-devel libffi-devel \
                    patch libyaml-devel zlib zlib-devel make autoconf automake libcurl-devel sqlite-devel mysql-devel
if [ $? -ne 0 ]; then installation_results+="必要なツールとライブラリのインストールが失敗しました。\n"; fi

# Rubyのインストール (rbenvを使用)
if [ ! -d "$HOME/.rbenv" ]; then
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
  echo 'eval "$(rbenv init -)"' >> ~/.bashrc
  source ~/.bashrc

  git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
fi
if [ $? -ne 0 ]; then installation_results+="rbenvのインストールが失敗しました。\n"; fi

# Ruby のインストール
if ! rbenv versions | grep -q $RUBY_VERSION; then
  rbenv install $RUBY_VERSION
  rbenv global $RUBY_VERSION
  rbenv rehash
  rbenv exec gem install bundler
fi
if [ $? -ne 0 ]; then installation_results+="Ruby $RUBY_VERSION のインストールが失敗しました。\n"; fi

# Node.js のインストールに必要なパッケージをインストール
sudo yum install -y wget tar gzip

# Node.js のダウンロード＆インストール
wget -nv https://d3rnber7ry90et.cloudfront.net/linux-x86_64/node-${NODE_VERSION}.tar.gz
tar -xf node-${NODE_VERSION}.tar.gz
sudo mv node-${NODE_VERSION} ${NODE_DIR}

# バイナリへのリンクを貼る
sudo ln -s ${NODE_DIR}/bin/corepack /usr/local/bin/corepack
sudo ln -s ${NODE_DIR}/bin/node /usr/local/bin/node
sudo ln -s ${NODE_DIR}/bin/npm /usr/local/bin/npm
sudo ln -s ${NODE_DIR}/bin/npx /usr/local/bin/npx

# ダウンロードしたアーカイブファイルを削除
rm -f node-${NODE_VERSION}.tar.gz

# yarn のインストールを確認し、必要ならインストール
if ! command -v yarn > /dev/null; then
  npm install -g yarn
  sudo ln -s ${NODE_DIR}/bin/yarn /usr/local/bin/yarn
  if [ $? -ne 0 ]; then installation_results+="yarnのインストールが失敗しました。\n"; fi
else
  echo "yarn はすでにインストールされています。"
fi

# Rails のインストール
gem install rails -v $RAILS_VERSION
if [ $? -ne 0 ];then installation_results+="Rails $RAILS_VERSION のインストールが失敗しました。\n"; fi

# Nokogiri のインストール
gem install nokogiri -v 1.16.6 -- --use-system-libraries
if [ $? -ne 0 ]; then installation_results+="Nokogiriのインストールが失敗しました。\n"; fi

# PHP のインストール
sudo amazon-linux-extras enable php${PHP_VERSION}
sudo yum install -y php-cli php-pdo php-mbstring php-mysqlnd php-json php-gd php-openssl php-curl php-xml php-intl 
if [ $? -ne 0 ]; then installation_results+="PHP $PHP_VERSION のインストールが失敗しました。\n"; fi

# composer のインストールを確認し、必要ならインストール
if ! command -v composer > /dev/null; then
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
  php composer-setup.php
  php -r "unlink('composer-setup.php');"
  sudo mv composer.phar /usr/local/bin/composer
  if [ $? -ne 0 ]; then installation_results+="Composerのインストールが失敗しました。\n"; fi
else
  echo "Composer はすでにインストールされています。"
fi

# MariaDB のインストールを確認し、必要ならインストール
if ! command -v mysql > /dev/null; then
  sudo amazon-linux-extras enable mariadb${MARIADB_VERSION}
  sudo yum -y install mariadb
  if [ $? -ne 0 ]; then installation_results+="MariaDB $MARIADB_VERSION のインストールが失敗しました。\n"; fi
else
  echo "MariaDB はすでにインストールされています。"
fi

# ターミナルのプロンプト表示設定
echo '#!/bin/sh' > /home/ec2-user/prompt.sh
echo 'parse_git_branch() {' >> /home/ec2-user/prompt.sh
echo '    git branch 2> /dev/null | sed -e '\''/^[^*]/d'\'' -e '\''s/* \(.*\)/ (\1)/'\''' >> /home/ec2-user/prompt.sh
echo '}' >> /home/ec2-user/prompt.sh
echo 'export PS1="\[\033[01;32m\]\u\[\033[00m\]:\[\033[34m\]\w\[\033[00m\]\$(parse_git_branch) $ "' >> /home/ec2-user/prompt.sh

sudo chmod 755 /home/ec2-user/prompt.sh
echo 'source ~/prompt.sh' >> /home/ec2-user/.bashrc
echo 'source ~/prompt.sh' >> /home/ec2-user/.bash_profile

# シェルの設定を再読み込み
source ~/.bashrc
source ~/.bash_profile

# 結果の表示
if [ -z "$installation_results" ]; then
  echo "すべてのライブラリが正常にインストールされました。環境構築が完了しました。"
else
  echo -e "$installation_results"
fi



