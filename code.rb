require 'csv'
require 'aws/s3'
require 'rubygems'
def write_file_to_s3()
AWS::S3::Base.establish_connection!(
 :access_key_id => 'AKIAISDDI6GM5OHP2BNA',
 :secret_access_key => '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'
)
file = 'summary.csv'
bucket = 'tictactoe-game5'
csv = AWS::S3::S3Object.value(file, bucket)
csv << "something"

AWS::S3::S3Object.store(File.basename(file), 
      csv,
      bucket,
      :access => :public_read)
end

write_file_to_s3