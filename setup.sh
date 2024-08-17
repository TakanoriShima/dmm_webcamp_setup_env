#!/bin/bash

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

# 必要なツールとライブラリのインストール
sudo yum install -y git bzip2 gcc openssl-devel readline-devel zlib-devel libffi-devel

# 開発ツールのインストール（主要な開発ライブラリを含む）
sudo yum groupinstall -y "Development Tools"

# rbenv のインストール
if [ ! -d "$HOME/.rbenv" ]; then
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
  echo 'eval "$(rbenv init -)"' >> ~/.bashrc
  source ~/.bashrc
fi

# ruby-build のインストール
if [ ! -d "$HOME/.rbenv/plugins/ruby-build" ]; then
  git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
fi

# Ruby 3.1.2 のインストール
if ! rbenv versions | grep -q '3.1.2'; then
  rbenv install 3.1.2
fi
rbenv global 3.1.2

# Nokogiri のインストール
gem install nokogiri -v 1.15.6 -- --use-system-libraries

# Rails 6.1.4 のインストール
gem install rails -v 6.1.4

# Node.js 18 のインストール
if ! node -v | grep -q 'v18'; then
  curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
  sudo yum install -y nodejs
fi

# Yarn のインストール
sudo npm install --global yarn

# PHP 8.2 のインストール
sudo amazon-linux-extras enable php8.2
sudo yum install -y php-cli php-pdo php-mbstring php-mysqlnd php-json php-gd php-openssl php-curl php-xml php-intl 

# composer のインストール
if ! command -v composer > /dev/null; then
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
  php composer-setup.php
  php -r "unlink('composer-setup.php');"
  sudo mv composer.phar /usr/local/bin/composer
fi

# MariaDB のインストール
sudo amazon-linux-extras enable mariadb10.5
sudo yum -y install mariadb

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

# シェルの設定を再読み込み
source ~/.bashrc
source ~/.bash_profile

# クリーンアップ
sudo yum clean all

echo "環境構築が完了しました。"
