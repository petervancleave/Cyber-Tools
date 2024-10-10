require 'openssl'

def factor_rsa_modulus(n)
  (2..Math.sqrt(n)).each do |i|
    return [i, n / i] if n % i == 0
  end
end

# example usage
n = 20 # n = p * q (RSA modulus, small example)
factors = factor_rsa_modulus(n)
puts "Factors of #{n}: #{factors[0]}, #{factors[1]}"

# factorization-based RSA key cracker. use to crack weak RSA keys in CTF
