# Command for testing
# bash loop.sh lb-fargate-012345678.us-east-2.elb.amazonaws.com

for i in {1..10000}
do
    # "number: $i"
    curl $1
    echo $i
done
