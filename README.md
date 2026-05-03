260503(수)
- 프로젝트 개설

flowchart TB
    User[User Browser]

    DNS[Route53<br/>example.com]
    CF[CloudFront<br/>HTTPS Edge]
    ACM1[ACM Certificate<br/>us-east-1<br/>for CloudFront]

    CW[CloudWatch<br/>Metrics / Alarm / Dashboard]
    SNS[SNS<br/>Alarm Notification]

    subgraph VPC[VPC]

        subgraph AZA[Availability Zone A]

            subgraph PublicA[Public Subnet A]
                ALB_A[ALB Node A]
                NAT_A[NAT Gateway]
            end

            subgraph PrivateAppA[Private App Subnet A]
                EC2A[EC2 App Server A<br/>Nginx]
            end

            subgraph PrivateDBA[Private DB Subnet A]
                RDSA[(RDS Primary)]
            end

        end

        subgraph AZB[Availability Zone B]

            subgraph PublicB[Public Subnet B]
                ALB_B[ALB Node B]
            end

            subgraph PrivateAppB[Private App Subnet B]
                EC2B[EC2 App Server B<br/>Nginx]
            end

            subgraph PrivateDBB[Private DB Subnet B]
                RDSB[(RDS Standby)]
            end

        end

    end

    ALB[Application Load Balancer<br/>HTTPS Listener]
    ACM2[ACM Certificate<br/>ap-northeast-2<br/>for ALB]

    User --> DNS
    DNS --> CF
    CF --> ALB

    ACM1 --> CF
    ACM2 --> ALB

    ALB --> ALB_A
    ALB --> ALB_B

    ALB_A --> EC2A
    ALB_B --> EC2B

    EC2A --> RDSA
    EC2B --> RDSA

    EC2A --> CW
    EC2B --> CW
    ALB --> CW
    RDSA --> CW
    RDSB --> CW

    CW --> SNS
