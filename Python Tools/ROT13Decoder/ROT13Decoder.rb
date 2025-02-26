def rot13(text)
  text.tr("A-Za-z", "N-ZA-Mn-za-m")
end

# example
ciphertext = "Uryyb Jbeyq"
puts rot13(ciphertext)  # Output: Hello World
