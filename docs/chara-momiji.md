# 紅葉

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
| ???   | ???  | ??? |

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
