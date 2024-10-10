require 'digest'

def hash_file(file_path)
  md5 = Digest::MD5.file(file_path).hexdigest
  sha1 = Digest::SHA1.file(file_path).hexdigest
  sha256 = Digest::SHA256.file(file_path).hexdigest

  puts "MD5:    #{md5}"
  puts "SHA1:   #{sha1}"
  puts "SHA256: #{sha256}"
end

# example 
file_path = 'test.txt'
hash_file(file_path)
