# CharacterAlarm

- アーキテクチャは MVP を採用
  - View にはレイアウトを書く
  - Presenter には View の操作に関する事
  - Model にはロジックを書き、状態を持たせます。


### 設定方法 ###

- Xcodeのインストール
- Bundlerのインストール
- Podのインストール

#### Xcodeのインストール ####

App Store から

#### rbenvのインストール ####

```
brew update
brew install rbenv ruby-build
rbenv install -l
rbenv install 2.7.1  # 最新版をインストール  3.2.2
rbenv versions  # インストール済みのバージョンを表示

cd
code .zprofile  # .zprofile に記述
```

```
eval "$(rbenv init -)"
```

```
rbenv global 2.7.1  # 使用バージョンを設定  3.2.2
ruby -v  # 切り替わっていることを確認
```

#### Bundlerのインストール ####

```
gem install bundler -v 2.4.13
gem list bundler
bundle -v
```

#### Podのインストール ####

```
bundle config set path vendor/bundle
bundle _2.4.13_ install
```

#### Mintのインストール ####

```
mint bootstrap
```

#### セットアップ ####

```
mint run xcodegen xcodegen generate
```

#### Podライブラリのアップデート ####

```
bundle exec pod update
```


Xcodeで起動する際は `*.xcodeproj` ではなく `*.xcworkspace` をダブルクリックして起動してください
以下のコマンドでも起動可能です

```
open CharacterAlarm.xcworkspace
```



```
image


audio
# 試しに聞く用のボイス
- xxxx.caf


api

```

LicensePlistの更新

```
mint run LicensePlist license-plist --output-path CharacterAlarm/Settings.bundle
```
