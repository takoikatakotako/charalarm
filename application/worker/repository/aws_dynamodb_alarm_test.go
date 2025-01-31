package repository

//// 追加したアラームをアラームタイムで検索できる
//// * 現在時刻を使っているため、1分以内にテストを実行すると失敗するので注意
//func TestInsertAndQueryByAlarmTime(t *testing.T) {
//	// AWS Repository
//	repository := AWS{Profile: "local"}
//
//	// 現在時刻取得
//	currentTime := time.Now()
//	hour := currentTime.Hour()
//	minute := currentTime.Minute()
//	weekday := currentTime.Weekday()
//
//	// Create Alarms
//	alarm0 := createAlarm()
//	alarm0.Hour = hour
//	alarm0.Minute = minute
//	alarm0.SetAlarmTime()
//
//	alarm1 := createAlarm()
//	alarm1.Hour = hour
//	alarm1.Minute = minute
//	alarm1.SetAlarmTime()
//
//	alarm2 := createAlarm()
//	alarm2.Hour = hour
//	alarm2.Minute = minute
//	alarm2.SetAlarmTime()
//
//	// Insert Alarms
//	err := repository.InsertAlarm(alarm0)
//	err = repository.InsertAlarm(alarm1)
//	err = repository.InsertAlarm(alarm2)
//	if err != nil {
//		t.Errorf("unexpected error: %v", err)
//	}
//
//	// Query
//	alarmList, err := repository.QueryByAlarmTime(hour, minute, weekday)
//	if err != nil {
//		t.Errorf("unexpected error: %v", err)
//	}
//
//	// Assert
//	assert.Equal(t, len(alarmList), 3)
//}
//
//func createAlarm() database.Alarm {
//	return database.Alarm{
//		AlarmID: uuid.New().String(),
//		UserID:  uuid.New().String(),
//		Type:    "IOS_VOIP_PUSH_NOTIFICATION",
//		Target:  "target",
//
//		Enable:         true,
//		Name:           "My Alarm",
//		Hour:           8,
//		Minute:         15,
//		Time:           "08-15",
//		TimeDifference: 0,
//
//		Sunday:    true,
//		Monday:    true,
//		Tuesday:   true,
//		Wednesday: true,
//		Thursday:  true,
//		Friday:    true,
//		Saturday:  true,
//	}
//}
//
//func (a *AWS) insertAlarm(alarm database.Alarm) error {
//	// Alarm のバリデーション
//	err := validator.ValidateAlarm(alarm)
//	if err != nil {
//		return err
//	}
//
//	client, err := a.createDynamoDBClient()
//	if err != nil {
//		fmt.Printf("err, %v", err)
//		return err
//	}
//
//	// 新規レコードの追加
//	av, err := attributevalue.MarshalMap(alarm)
//	if err != nil {
//		fmt.Printf("dynamodb marshal: %s\n", err.Error())
//		return err
//	}
//	_, err = client.PutItem(context.Background(), &dynamodb.PutItemInput{
//		TableName: aws.String(database.AlarmTableName),
//		Item:      av,
//	})
//	if err != nil {
//		fmt.Printf("put item: %s\n", err.Error())
//		return err
//	}
//
//	return nil
//}
