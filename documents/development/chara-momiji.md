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

[com.senpu-ki-soft.momiji.json](chara-resource/com.senpu-ki-soft.momiji.json) を使用。

```
aws dynamodb put-item \
    --table-name chara-table \
    --item file://chara-resource/com.senpu-ki-soft.momiji.json  \
    --profile {PROFILE}
```
