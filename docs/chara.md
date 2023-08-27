# キャラクター

キャラクターの画像は [GoogleDrive](https://drive.google.com/drive/folders/1A4Rrh5q8ufCGUdfPfA4NJAn8838ZtHEx?usp=sharing)
に格納されています。（要アクセス権付与）
DDLは [https://github.com/takoikatakotako/charalarm-backend/blob/develop/localstack/createTable.sh](https://github.com/takoikatakotako/charalarm-backend/blob/develop/localstack/createTable.sh) にも格納されています。

## 井上結衣

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
    --item '{"charaID":{"S":"com.charalarm.yui"},"enable":{"BOOL":true},"name":{"S":"井上結衣"},"created_at":{"S":"2023-06-03"},"updated_at":{"S":"2023-06-14"},"description":{"S":"井上結衣です。プログラマーとして働いていてこのアプリを作っています。このアプリをたくさん使ってくれると嬉しいです、よろしくね！"},"profiles":{"L":[{"M":{"title":{"S":"イラストレーター"},"name":{"S":"さいもん"},"url":{"S":"https://twitter.com/simon_ns"}}},{"M":{"title":{"S":"声優"},"name":{"S":"Mai"},"url":{"S":"https://twitter.com/mai_mizuiro"}}},{"M":{"title":{"S":"スクリプト"},"name":{"S":"小旗ふたる！"},"url":{"S":"https://twitter.com/Kass_kobataku"}}}]},"calls":{"L":[{"M":{"message":{"S":"もしもし、起きる時間だよ"},"voiceFileName":{"S":"com-charalarm-yui-15.caf"}}},{"M":{"message":{"S":"おはよう、今日もいい天気だよ"},"voiceFileName":{"S":"com-charalarm-yui-16.caf"}}},{"M":{"message":{"S":"もしもし、昨日は夜遅くまで起きてたのかな?"},"voiceFileName":{"S":"com-charalarm-yui-17.caf"}}},{"M":{"message":{"S":"もしもし、まだ寝てるの?"},"voiceFileName":{"S":"com-charalarm-yui-18.caf"}}},{"M":{"message":{"S":"あっ、もしもし。起こしちゃった？"},"voiceFileName":{"S":"com-charalarm-yui-19.caf"}}},{"M":{"message":{"S":"もしもーし、お疲れ様"},"voiceFileName":{"S":"com-charalarm-yui-20.caf"}}}]},"expressions":{"M":{"normal":{"M":{"imageFileNames":{"L":[{"S":"normal.png"}]},"voiceFileNames":{"L":[{"S":"com-charalarm-yui-1.caf"},{"S":"com-charalarm-yui-4.caf"},{"S":"com-charalarm-yui-5.caf"}]}}},"smile":{"M":{"imageFileNames":{"L":[{"S":"smile.png"}]},"voiceFileNames":{"L":[{"S":"com-charalarm-yui-2.caf"},{"S":"com-charalarm-yui-3.caf"}]}}},"confused":{"M":{"imageFileNames":{"L":[{"S":"confused.png"}]},"voiceFileNames":{"L":[{"S":"com-charalarm-yui-5.caf"},{"S":"com-charalarm-yui-12.caf"},{"S":"com-charalarm-yui-13.caf"},{"S":"com-charalarm-yui-14.caf"}]}}}}}}' \
    --profile {PROFILE}
```


## 紅葉

旋風鬼のマスコットキャラクターさんです。

### CharaID

com.senpu-ki-soft.momiji

### description

金髪紅眼の美少女。疲れ気味のあなたを心配して様々な癒しを、と考えている。その正体は幾百年を生きる鬼の末裔。あるいはあなたに恋慕を抱く彼女。ちょっと素直になりきれないものの、なんやかんやいってそばにいてくれる面倒見のいい少女。日々あなたの生活を見届けている。「わっち？
名は紅葉でありんす。主様の支えになれるよう、掃除でもみみかきでもなんでも言っておくんなんし。か、かわいい？ い、いきなりそんなこと言わないでおくんなんし！」

### profiles

| title | name | url |
|-------|------|-----|
| ???   | ???  | ??? |
| ???   | ???  | ??? |
| ???   | ???！ | ??? |

### calls

| message    | voice                            |
|------------|----------------------------------|
| 紅葉さんの天気だね。 | call-on-weekday-morning.caf      |
| 紅葉さんの肩凝るねー | call-on-weekday-afternoon.caf    |
| 紅葉さんのボイス3  | call-holiday-scheduled-alarm.caf |
| 紅葉さんのボイス4  | call-holiday-no-scheduled.caf    |
| 紅葉さんのボイス   | call-small-talk.caf              |

### expressions

**normal**

images

- normal.png

voices

- tap-general-1.caf
- tap-general-2.caf
- tap-general-3.caf
- tap-general-4.caf
- tap-general-5.caf

### DDL

```
aws dynamodb put-item \
    --table-name chara-table \
    --item '{"charaID":{"S":"com.senpu-ki-soft.momiji"},"enable":{"BOOL":true},"name":{"S":"紅葉"},"created_at":{"S":"2023-06-05"},"updated_at":{"S":"2023-06-14"},"description":{"S":"金髪紅眼の美少女。疲れ気味のあなたを心配して様々な癒しを、と考えている。その正体は幾百年を生きる鬼の末裔。あるいはあなたに恋慕を抱く彼女。ちょっと素直になりきれないものの、なんやかんやいってそばにいてくれる面倒見のいい少女。日々あなたの生活を見届けている。「わっち？　名は紅葉でありんす。主様の支えになれるよう、掃除でもみみかきでもなんでも言っておくんなんし。か、かわいい？　い、いきなりそんなこと言わないでおくんなんし！」"},"calls":{"L":[{"M":{"message":{"S":"紅葉さんの天気だね。"},"voiceFileName":{"S":"call-on-weekday-morning.caf"}}},{"M":{"message":{"S":"紅葉さんの肩凝るねー"},"voiceFileName":{"S":"call-on-weekday-afternoon.caf"}}},{"M":{"message":{"S":"紅葉さんのボイス3"},"voiceFileName":{"S":"call-holiday-scheduled-alarm.caf"}}},{"M":{"message":{"S":"紅葉さんのボイス4"},"voiceFileName":{"S":"call-holiday-no-scheduled.caf"}}},{"M":{"message":{"S":"紅葉さんのボイス"},"voiceFileName":{"S":"call-small-talk.caf"}}}]},"expressions":{"M":{"normal":{"M":{"imageFileNames":{"L":[{"S":"normal.png"}]},"voiceFileNames":{"L":[{"S":"tap-general-1.caf"},{"S":"tap-general-2.caf"},{"S":"tap-general-3.caf"},{"S":"tap-general-4.caf"},{"S":"tap-general-5.caf"}]}}}}}}' \
    --profile {PROFILE}
```