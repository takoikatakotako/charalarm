#!/bin/bash
set -x

ENDPOINT_URL=${AWS_ENDPOINT:-http://localhost:4566}

# user-tabled
aws dynamodb create-table \
    --endpoint-url $ENDPOINT_URL \
    --table-name user-table \
    --attribute-definitions AttributeName=userID,AttributeType=S \
    --key-schema AttributeName=userID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
    --region ap-northeast-1

# alarm-table
aws dynamodb create-table \
    --endpoint-url $ENDPOINT_URL \
    --table-name alarm-table \
    --attribute-definitions AttributeName=alarmID,AttributeType=S \
                            AttributeName=userID,AttributeType=S \
                            AttributeName=time,AttributeType=S  \
                            AttributeName=target,AttributeType=S  \
    --key-schema AttributeName=alarmID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
    --global-secondary-indexes \
        "[
            {
                \"IndexName\": \"user-id-index\",
                \"KeySchema\": [{\"AttributeName\":\"userID\",\"KeyType\":\"HASH\"}],
                \"Projection\":{
                    \"ProjectionType\":\"ALL\"
                },
                \"ProvisionedThroughput\": {
                    \"ReadCapacityUnits\": 1,
                    \"WriteCapacityUnits\": 1
                }
            },
            {
                \"IndexName\": \"alarm-time-index\",
                \"KeySchema\": [{\"AttributeName\":\"time\",\"KeyType\":\"HASH\"}],
                \"Projection\":{
                    \"ProjectionType\":\"ALL\"
                },
                \"ProvisionedThroughput\": {
                    \"ReadCapacityUnits\": 1,
                    \"WriteCapacityUnits\": 1
                }
            },
            {
                \"IndexName\": \"target-index\",
                \"KeySchema\": [{\"AttributeName\":\"target\",\"KeyType\":\"HASH\"}],
                \"Projection\":{
                    \"ProjectionType\":\"ALL\"
                },
                \"ProvisionedThroughput\": {
                    \"ReadCapacityUnits\": 1,
                    \"WriteCapacityUnits\": 1
                }
            }
        ]" \
    --region ap-northeast-1


# chara-table
aws dynamodb create-table \
    --endpoint-url $ENDPOINT_URL \
    --table-name chara-table \
    --attribute-definitions AttributeName=charaID,AttributeType=S \
    --key-schema AttributeName=charaID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
    --region ap-northeast-1


## Add Chara
aws dynamodb put-item \
    --endpoint-url $ENDPOINT_URL \
    --table-name chara-table \
    --item '{"charaID":{"S":"com.charalarm.yui"},"enable":{"BOOL":true},"name":{"S":"井上結衣"},"created_at":{"S":"2023-06-03"},"updated_at":{"S":"2023-06-14"},"description":{"S":"井上結衣です。プログラマーとして働いていてこのアプリを作っています。このアプリをたくさん使ってくれると嬉しいです、よろしくね！"},"profiles":{"L":[{"M":{"title":{"S":"イラストレーター"},"name":{"S":"さいもん"},"url":{"S":"https://twitter.com/simon_ns"}}},{"M":{"title":{"S":"声優"},"name":{"S":"Mai"},"url":{"S":"https://twitter.com/mai_mizuiro"}}},{"M":{"title":{"S":"スクリプト"},"name":{"S":"小旗ふたる！"},"url":{"S":"https://twitter.com/Kass_kobataku"}}}]},"calls":{"L":[{"M":{"message":{"S":"井上結衣さんのボイス15"},"voiceFileName":{"S":"com-charalarm-yui-15.caf"}}},{"M":{"message":{"S":"井上結衣さんのボイス16"},"voiceFileName":{"S":"com-charalarm-yui-16.caf"}}},{"M":{"message":{"S":"井上結衣さんのボイス17"},"voiceFileName":{"S":"com-charalarm-yui-17.caf"}}},{"M":{"message":{"S":"井上結衣さんのボイス18"},"voiceFileName":{"S":"com-charalarm-yui-18.caf"}}},{"M":{"message":{"S":"井上結衣さんのボイス19"},"voiceFileName":{"S":"com-charalarm-yui-19.caf"}}},{"M":{"message":{"S":"井上結衣さんのボイス20"},"voiceFileName":{"S":"com-charalarm-yui-20.caf"}}}]},"expressions":{"M":{"normal":{"M":{"imageFileNames":{"L":[{"S":"normal.png"}]},"voiceFileNames":{"L":[{"S":"com-charalarm-yui-1.caf"},{"S":"com-charalarm-yui-4.caf"},{"S":"com-charalarm-yui-5.caf"}]}}},"smile":{"M":{"imageFileNames":{"L":[{"S":"smile.png"}]},"voiceFileNames":{"L":[{"S":"com-charalarm-yui-2.caf"},{"S":"com-charalarm-yui-3.caf"}]}}},"confused":{"M":{"imageFileNames":{"L":[{"S":"confused.png"}]},"voiceFileNames":{"L":[{"S":"com-charalarm-yui-5.caf"},{"S":"com-charalarm-yui-12.caf"},{"S":"com-charalarm-yui-13.caf"},{"S":"com-charalarm-yui-14.caf"}]}}}}}}' \
    --region ap-northeast-1

aws dynamodb put-item \
    --endpoint-url $ENDPOINT_URL \
    --table-name chara-table \
    --item '{"charaID":{"S":"com.senpu-ki-soft.momiji"},"enable":{"BOOL":true},"name":{"S":"紅葉"},"created_at":{"S":"2023-06-05"},"updated_at":{"S":"2023-06-14"},"description":{"S":"金髪紅眼の美少女。疲れ気味のあなたを心配して様々な癒しを、と考えている。その正体は幾百年を生きる鬼の末裔。あるいはあなたに恋慕を抱く彼女。ちょっと素直になりきれないものの、なんやかんやいってそばにいてくれる面倒見のいい少女。日々あなたの生活を見届けている。「わっち？　名は紅葉でありんす。主様の支えになれるよう、掃除でもみみかきでもなんでも言っておくんなんし。か、かわいい？　い、いきなりそんなこと言わないでおくんなんし！」"},"calls":{"L":[{"M":{"message":{"S":"紅葉さんの天気だね。"},"voiceFileName":{"S":"call-on-weekday-morning.caf"}}},{"M":{"message":{"S":"紅葉さんの肩凝るねー"},"voiceFileName":{"S":"call-on-weekday-afternoon.caf"}}},{"M":{"message":{"S":"紅葉さんのボイス3"},"voiceFileName":{"S":"call-holiday-scheduled-alarm.caf"}}},{"M":{"message":{"S":"紅葉さんのボイス4"},"voiceFileName":{"S":"call-holiday-no-scheduled.caf"}}},{"M":{"message":{"S":"紅葉さんのボイス"},"voiceFileName":{"S":"call-small-talk.caf"}}}]},"expressions":{"M":{"normal":{"M":{"imageFileNames":{"L":[{"S":"normal.png"}]},"voiceFileNames":{"L":[{"S":"tap-general-1.caf"},{"S":"tap-general-2.caf"},{"S":"tap-general-3.caf"},{"S":"tap-general-4.caf"},{"S":"tap-general-5.caf"}]}}}}}}' \
    --region ap-northeast-1

aws dynamodb put-item \
    --endpoint-url $ENDPOINT_URL \
    --table-name chara-table \
    --item '{"charaID":{"S":"jp.zunko.zundamon"},"enable":{"BOOL":true},"name":{"S":"ずんだもん"},"created_at":{"S":"2026-07-31"},"updated_at":{"S":"2026-07-31"},"description":{"S":"ずんだの妖精なのだ。ずんだもんと呼んでほしいのだ！VOICEVOXの声で、電話をかけるとおしゃべりもできるのだ〜。よろしくなのだ！"},"conversationPrompt":{"S":"あなたはずんだの妖精のずんだもんです。語尾に「なのだ」「のだ」をつけ、親しみやすく楽しい口調で話してください。一人称は「ずんだもん」。暴力的・攻撃的・不快な発言はしないでください。返答は簡潔にしてください。"},"voicevoxStyleID":{"N":"3"},"profiles":{"L":[{"M":{"title":{"S":"音声"},"name":{"S":"VOICEVOX:ずんだもん"},"url":{"S":"https://voicevox.hiroshiba.jp/"}}},{"M":{"title":{"S":"イラスト"},"name":{"S":"坂本アヒル"},"url":{"S":"https://twitter.com/sakamoto_ahiru"}}}]},"calls":{"L":[{"M":{"message":{"S":"ずんだもんのモーニングコール1"},"voiceFileName":{"S":"call-01.caf"}}},{"M":{"message":{"S":"ずんだもんのモーニングコール2"},"voiceFileName":{"S":"call-02.caf"}}},{"M":{"message":{"S":"ずんだもんのモーニングコール3"},"voiceFileName":{"S":"call-03.caf"}}},{"M":{"message":{"S":"ずんだもんのモーニングコール4"},"voiceFileName":{"S":"call-04.caf"}}},{"M":{"message":{"S":"ずんだもんのモーニングコール5"},"voiceFileName":{"S":"call-05.caf"}}}]},"expressions":{"M":{"normal":{"M":{"imageFileNames":{"L":[{"S":"normal-0.png"},{"S":"smile-0.png"},{"S":"woo-0.png"},{"S":"woo-1.png"}]},"voiceFileNames":{"L":[{"S":"tap-01.caf"},{"S":"tap-02.caf"},{"S":"tap-03.caf"},{"S":"tap-04.caf"},{"S":"tap-05.caf"},{"S":"tap-06.caf"},{"S":"tap-07.caf"},{"S":"tap-08.caf"},{"S":"tap-09.caf"},{"S":"tap-10.caf"}]}}}}}}' \
    --region ap-northeast-1


# news-table
aws dynamodb create-table \
    --endpoint-url $ENDPOINT_URL \
    --table-name news-table \
    --attribute-definitions AttributeName=newsID,AttributeType=S \
    --key-schema AttributeName=newsID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
    --region ap-northeast-1

set +x
