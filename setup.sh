#!/bin/bash

# 結果を格納する変数を初期化
installation_results=""

# パッケージ情報の更新
sudo yum update -y
if [ $? -ne 0 ]; then installation_results+="パッケージ情報の更新が失敗しました。\n"; fi

# 必要なツールとライブラリのインストール
sudo yum install -y git curl bzip2 gcc gcc-c++ make openssl-devel readline-devel zlib-devel libffi-devel
sudo yum -y install patch libyaml-devel zlib zlib-devel libffi-devel make autoconf automake libcurl-devel sqlite-devel mysql-devel
if [ $? -ne 0 ]; then installation_results+="必要なツールとライブラリのインストールが失敗しました。\n"; fi

# Rubyのインストール (rbenvを使用)
if [ ! -d "$HOME/.rbenv" ]; then
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
  echo 'eval "$(rbenv init -)"' >> ~/.bashrc
  # ~/.bashrc の変更を反映
  source ~/.bashrc

  # ruby-buildのインストール
  git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
fi
if [ $? -ne 0 ]; then installation_results+="rbenvのインストールが失敗しました。\n"; fi

# Ruby 3.1.2 のインストール
if ! rbenv versions | grep -q '3.1.2'; then
  rbenv install 3.1.2
  rbenv global 3.1.2
  rbenv rehash
  rbenv exec gem install bundler
fi
if [ $? -ne 0 ]; then installation_results+="Ruby 3.1.2のインストールが失敗しました。\n"; fi

# Node.js 16 のバージョンとインストールディレクトリを設定
NODE_VER=v18.18.2
NODE_DIR=/usr/local/share/node 

# Node.js 18 のインストールに必要なパッケージをインストール
sudo yum install -y wget tar gzip

# Node.js 18 のダウンロード＆インストール
wget -nv https://d3rnber7ry90et.cloudfront.net/linux-x86_64/node-${NODE_VER}.tar.gz
tar -xf node-${NODE_VER}.tar.gz
sudo mv node-${NODE_VER} ${NODE_DIR}

# バイナリへのリンクを貼る
sudo ln -s ${NODE_DIR}/bin/corepack /usr/local/bin/corepack
sudo ln -s ${NODE_DIR}/bin/node /usr/local/bin/node
sudo ln -s ${NODE_DIR}/bin/npm /usr/local/bin/npm
sudo ln -s ${NODE_DIR}/bin/npx /usr/local/bin/npx

# yarn のインストール
npm install -g yarn

# Rails 6.1.4 のインストール
gem install rails -v 6.1.4
if [ $? -ne 0 ]; then installation_results+="Rails 6.1.4のインストールが失敗しました。\n"; fi

# Nokogiri のインストール
gem install nokogiri -v 1.16.6 -- --use-system-libraries
if [ $? -ne 0 ]; then installation_results+="Nokogiriのインストールが失敗しました。\n"; fi

# # Composer のインストール
# if ! command -v composer > /dev/null; then
#   php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
#   php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
#   php composer-setup.php
#   php -r "unlink('composer-setup.php');"
#   sudo mv composer.phar /usr/local/bin/composer
# fi
# if [ $? -ne 0 ]; then installation_results+="Composerのインストールが失敗しました。\n"; fi

# PHP 8.2 のインストール
sudo amazon-linux-extras enable php8.2
sudo yum install -y php-cli php-pdo php-mbstring php-mysqlnd php-json php-gd php-openssl php-curl php-xml php-intl 
if [ $? -ne 0 ]; then installation_results+="PHP 8.2のインストールが失敗しました。\n"; fi

# composer のインストール
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"
sudo mv composer.phar /usr/local/bin/composer

# MariaDB のインストール
sudo amazon-linux-extras enable mariadb10.5
sudo yum -y install mariadb

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


