Demo Run Through backing up to demo aws account

prereqs:
- correct aws keys in correct location
- - AWS Demo User: write-encoded-backups-dev
- - Put creds into your local macbook home dir: ~/.aws/.pg-aws/credentials
- - Then the key and secret need to be added to their own files in the same location 
- - - $echo -n 'key' > credentials_key
- - - $echo -n 'secret' > credentials_secret
- s3 buckets made for testing or prod
- - backup-backup-buckets: s3://buckets/encoded-backups-dev/production-pg93pre11
- - pg11-backup-bucket: s3://buckets/encoded-backups-dev/production-pg11
- - clear the buckets if not first run

LOCAL
$cd your-encoded-repo
$git fetch origin -p
$git checkout -b preENCD-3336-Upgrade-postgres-11 origin/preENCD-3336-Upgrade-postgres-11
$bin/deploy -n 3336j --release-candidate
# Wait for deployment to finish
$./move-aws-creds-to-demo.sh 3336j.ubu
$ssh 3336j.ubu

REMOTE 
$cd /home/ubuntu/encoded/cloud-config/deploy-run-scripts/update-to-pg11
$./update-pg93t11.sh live demo waleokayNOT
# Do what the output tells you

LOCAL
$cd your-encoded-repo
$git fetch origin -p
$git checkout -b ENCD-3336-Upgrade-postgres-11 origin/ENCD-3336-Upgrade-postgres-11
$bin/deploy -n 3336l-pg11 --release-candidate --wale-s3-prefix $pg11-backup-bucket
