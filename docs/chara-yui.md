# 井上結衣

Charalarmのマスコットキャラクターです。

### CharaID

com.charalarm.yui

### description

井上結衣です。プログラマーとして働いていてこのアプリを作っています。このアプリをたくさん使ってくれると嬉しいです、よろしくね！

### profiles

| title    | name   | url                                                                    |
|----------|--------|------------------------------------------------------------------------|
| イラストレーター | さいもん   | [https://twitter.com/simon_ns](https://twitter.com/simon_ns)           |
| 声優       | Mai    | [https://twitter.com/mai_mizuiro](https://twitter.com/mai_mizuiro )    |
| スクリプト    | 小旗ふたる！ | [https://twitter.com/Kass_kobataku](https://twitter.com/Kass_kobataku) |

### calls

| message               | voice                    |
|-----------------------|--------------------------|
| もしもし、起きる時間だよ          | com-charalarm-yui-15.caf |
| おはよう、今日もいい天気だよ        | com-charalarm-yui-16.caf |
| もしもし、昨日は夜遅くまで起きてたのかな? | com-charalarm-yui-17.caf |
| もしもし、まだ寝てるの?          | com-charalarm-yui-18.caf |
| あっ、もしもし。起こしちゃった？      | com-charalarm-yui-19.caf |
| もしもーし、お疲れ様            | com-charalarm-yui-20.caf |

### expressions

**normal**

images

- normal.png

voices

- com-charalarm-yui-1.caf
- com-charalarm-yui-4.caf
- com-charalarm-yui-5.caf

**smile**

images

- smile.png

voices

- com-charalarm-yui-2.caf
- com-charalarm-yui-3.caf

**confused**

images

- confused.png

voices

- com-charalarm-yui-5.caf"
- com-charalarm-yui-12.caf
- com-charalarm-yui-13.caf
- com-charalarm-yui-14.caf

### DDL

```
aws dynamodb put-item \
    --table-name chara-table \
    --item file://chara-resource/com.charalarm.uyi.json \
    --profile {PROFILE}
```