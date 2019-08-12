package main

import (
	"encoding/json"
	"fmt"
	"math/rand"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/satori/go.uuid"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/kinesis"
)

var awsSession = session.Must(session.NewSession(&aws.Config{}))
var kinesisSvc = kinesis.New(awsSession)
var kinesisStreamNamePrefix = os.Getenv("kinesis_stream_prefix")

func transformAttribute(av *events.DynamoDBAttributeValue) interface{} {
	var v interface{}

	switch av.DataType() {
	case events.DataTypeBinary:
		v = av.Binary()

	case events.DataTypeBoolean:
		v = av.Boolean()

	case events.DataTypeBinarySet:
		v = av.BinarySet()

	case events.DataTypeList:
		list := av.List()
		res := []interface{}{}
		for i := 0; i < len(list); i++ {
			val := transformAttribute(&list[i])
			res = append(res, val)
		}
		v = res

	case events.DataTypeMap:
		m := av.Map()
		res := make(map[string]interface{})
		for key, val := range m {
			res[key] = transformAttribute(&val)
		}
		v = res

	case events.DataTypeNumber:
		val := av.Number()
		asInt, err := strconv.ParseInt(val, 10, 64)
		if err != nil {
			asFloat, _ := strconv.ParseFloat(val, 64)
			return asFloat
		}
		return asInt

	case events.DataTypeNumberSet:
		v = av.NumberSet()

	case events.DataTypeNull:
		v = nil

	case events.DataTypeString:
		v = av.String()

	case events.DataTypeStringSet:
		v = av.StringSet()
	}

	return v
}

func handler(e events.DynamoDBEvent) error {
	input := make(map[string]*kinesis.PutRecordsInput)
	var item map[string]events.DynamoDBAttributeValue

	for i := 0; i < len(e.Records); i++ {
		m := make(map[string]interface{})
		record := e.Records[i]

		// example: arn:aws:dynamodb:eu-central-1:123456789:table/MY_DYNAMODB_TABLE_NAME/stream/2018-09-18T12:40:10.451
		arnSplit := strings.Split(record.EventSourceArn, ":table/")
		streamName := kinesisStreamNamePrefix + strings.Split(arnSplit[1], "/")[0]
		switch record.EventName {
		case "REMOVE":
			item = record.Change.OldImage
			if len(item) == 0 {
				item = record.Change.Keys
			}
		default:
			item = record.Change.NewImage
		}
		item["__operation"] = events.NewStringAttribute(record.EventName)

		for key, value := range item {
			m[strings.ToLower(key)] = transformAttribute(&value)
		}

		b, err := json.Marshal(m)
		if err != nil {
			fmt.Printf("cannot unmarshal json from stream %v, error is: %v\n", streamName, err)
			return err
		}

		newLine := "\n"
		b = append(b, newLine...)
		uuid := uuid.Must(uuid.NewV4()).String()

		recordItem := &kinesis.PutRecordsRequestEntry{
			Data: b,
			PartitionKey: &uuid,
		}

		if _, found := input[streamName]; !found {
			input[streamName] = &kinesis.PutRecordsInput{
				StreamName: &streamName,
				Records:            []*kinesis.PutRecordsRequestEntry{},
			}
		}

		input[streamName].Records = append(input[streamName].Records, recordItem)
		if len(input[streamName].Records) == 500 {
			output, err := kinesisSvc.PutRecords(input[streamName])
			if err != nil {
				fmt.Printf("cannot put record to kinesis stream %v, error is: %v\n", streamName, err)
				return err
			}
			input[streamName].Records = []*kinesis.PutRecordsRequestEntry{}

			failedCount := *output.FailedRecordCount
			if failedCount > 0 {
				r := rand.Intn(4) + 1
				time.Sleep(time.Duration(r) * time.Second)
				return fmt.Errorf("too many failed records in batch for stream %v: %v", streamName, failedCount)
			}
		}
	}
	for _, value := range input {
		if len(value.Records) == 0 {
			continue
		}
		output, err := kinesisSvc.PutRecords(value)
		if err != nil {
			fmt.Printf("cannot put records to kinesis stream %v, error is: %v\n", *value.StreamName, err)
			return err
		}

		failedCount := *output.FailedRecordCount
		if failedCount > 0 {
			r := rand.Intn(4) + 1
			time.Sleep(time.Duration(r) * time.Second)
			return fmt.Errorf("too many failed records in batch for stream %v: %v", *value.StreamName, failedCount)
		}
	}
	return nil
}

func main() {
	lambda.Start(handler)
}
