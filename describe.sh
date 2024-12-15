echo "the one where postman hangs to get the token" > describe.txt
aws cognito-idp describe-user-pool --user-pool-id us-east-2_UdALBWOOs >> describe.txt
aws cognito-idp describe-user-pool-client --user-pool-id us-east-2_UdALBWOOs --client-id 3u7fj71ci0nfjlfo0hr59ap8lc >> describe.txt
aws cognito-idp describe-user-pool-domain --domain my-api-domain-1734234550 >> describe.txt

echo "the one that works" >> describe.txt
aws cognito-idp describe-user-pool --user-pool-id eu-north-1_T7S4ipgqa --profile julienpmjacquet+upwork >> describe.txt
aws cognito-idp describe-user-pool-client --user-pool-id eu-north-1_T7S4ipgqa --client-id li9u962p0ugjvsj74ulq7psk --profile julienpmjacquet+upwork >> describe.txt
aws cognito-idp describe-user-pool-domain --domain eu-north-1t7s4ipgqa --profile julienpmjacquet+upwork >> describe.txt