import hashlib,binascii

passwd = input("Enter the password to hash: ")

hash = hashlib.new('md4', passwd.encode('utf-16le')).digest()

print(binascii.hexlify(hash))