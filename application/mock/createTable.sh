#!/bin/bash
set -x

# user-tabled
awslocal dynamodb create-table \
    --table-name user-table \
    --attribute-definitions AttributeName=userID,AttributeType=S \
    --key-schema AttributeName=userID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
    --region ap-northeast-1

# alarm-table
awslocal dynamodb create-table \
    --table-name alarm-table \
    --attribute-definitions AttributeName=alarmID,AttributeType=S \
                            AttributeName=userID,AttributeType=S \
                            AttributeName=time,AttributeType=S  \
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
            }
        ]" \
    --region ap-northeast-1


# chara-table
awslocal dynamodb create-table \
    --table-name chara-table \
    --attribute-definitions AttributeName=charaID,AttributeType=S \
    --key-schema AttributeName=charaID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
    --region ap-northeast-1


## Add Chara
awslocal dynamodb put-item \
    --table-name chara-table \
    --item '{"charaID":{"S":"com.charalarm.yui"},"enable":{"BOOL":true},"name":{"S":"井上結衣"},"created_at":{"S":"2023-06-03"},"updated_at":{"S":"2023-06-14"},"description":{"S":"井上結衣です。プログラマーとして働いていてこのアプリを作っています。このアプリをたくさん使ってくれると嬉しいです、よろしくね！"},"profiles":{"L":[{"M":{"title":{"S":"イラストレーター"},"name":{"S":"さいもん"},"url":{"S":"https://twitter.com/simon_ns"}}},{"M":{"title":{"S":"声優"},"name":{"S":"Mai"},"url":{"S":"https://twitter.com/mai_mizuiro"}}},{"M":{"title":{"S":"スクリプト"},"name":{"S":"小旗ふたる！"},"url":{"S":"https://twitter.com/Kass_kobataku"}}}]},"calls":{"L":[{"M":{"message":{"S":"井上結衣さんのボイス15"},"voiceFileName":{"S":"com-charalarm-yui-15.caf"}}},{"M":{"message":{"S":"井上結衣さんのボイス16"},"voiceFileName":{"S":"com-charalarm-yui-16.caf"}}},{"M":{"message":{"S":"井上結衣さんのボイス17"},"voiceFileName":{"S":"com-charalarm-yui-17.caf"}}},{"M":{"message":{"S":"井上結衣さんのボイス18"},"voiceFileName":{"S":"com-charalarm-yui-18.caf"}}},{"M":{"message":{"S":"井上結衣さんのボイス19"},"voiceFileName":{"S":"com-charalarm-yui-19.caf"}}},{"M":{"message":{"S":"井上結衣さんのボイス20"},"voiceFileName":{"S":"com-charalarm-yui-20.caf"}}}]},"expressions":{"M":{"normal":{"M":{"imageFileNames":{"L":[{"S":"normal.png"}]},"voiceFileNames":{"L":[{"S":"com-charalarm-yui-1.caf"},{"S":"com-charalarm-yui-4.caf"},{"S":"com-charalarm-yui-5.caf"}]}}},"smile":{"M":{"imageFileNames":{"L":[{"S":"smile.png"}]},"voiceFileNames":{"L":[{"S":"com-charalarm-yui-2.caf"},{"S":"com-charalarm-yui-3.caf"}]}}},"confused":{"M":{"imageFileNames":{"L":[{"S":"confused.png"}]},"voiceFileNames":{"L":[{"S":"com-charalarm-yui-5.caf"},{"S":"com-charalarm-yui-12.caf"},{"S":"com-charalarm-yui-13.caf"},{"S":"com-charalarm-yui-14.caf"}]}}}}}}' \
    --region ap-northeast-1

awslocal dynamodb put-item \
    --table-name chara-table \
    --item '{"charaID":{"S":"com.senpu-ki-soft.momiji"},"enable":{"BOOL":true},"name":{"S":"紅葉"},"created_at":{"S":"2023-06-05"},"updated_at":{"S":"2023-06-14"},"description":{"S":"金髪紅眼の美少女。疲れ気味のあなたを心配して様々な癒しを、と考えている。その正体は幾百年を生きる鬼の末裔。あるいはあなたに恋慕を抱く彼女。ちょっと素直になりきれないものの、なんやかんやいってそばにいてくれる面倒見のいい少女。日々あなたの生活を見届けている。「わっち？　名は紅葉でありんす。主様の支えになれるよう、掃除でもみみかきでもなんでも言っておくんなんし。か、かわいい？　い、いきなりそんなこと言わないでおくんなんし！」"},"calls":{"L":[{"M":{"message":{"S":"紅葉さんの天気だね。"},"voiceFileName":{"S":"call-on-weekday-morning.caf"}}},{"M":{"message":{"S":"紅葉さんの肩凝るねー"},"voiceFileName":{"S":"call-on-weekday-afternoon.caf"}}},{"M":{"message":{"S":"紅葉さんのボイス3"},"voiceFileName":{"S":"call-holiday-scheduled-alarm.caf"}}},{"M":{"message":{"S":"紅葉さんのボイス4"},"voiceFileName":{"S":"call-holiday-no-scheduled.caf"}}},{"M":{"message":{"S":"紅葉さんのボイス"},"voiceFileName":{"S":"call-small-talk.caf"}}}]},"expressions":{"M":{"normal":{"M":{"imageFileNames":{"L":[{"S":"normal.png"}]},"voiceFileNames":{"L":[{"S":"tap-general-1.caf"},{"S":"tap-general-2.caf"},{"S":"tap-general-3.caf"},{"S":"tap-general-4.caf"},{"S":"tap-general-5.caf"}]}}}}}}' \
    --region ap-northeast-1

set +x
