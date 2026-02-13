# # int, float, bool, string, char,...
# myvar = 12

# print(5//2)

# myfloat = 12.5

# mybool = True

# mystring1 = "hello"

# mystring2 = "hello"


# print(myvar)

# ## Conditionals
# x=7
# if 5 < x or myvar ==12:
#     print (":p")
# # and: both sides MUST be True
# # or: either can be True
# # xor: only one is allowed to be true 

# #comparison operators: < > == <= >=
# # not 

# print(( 4 < 5 ))
# print(not( 4 < 5 ))

# # Arithmetric Operators: + - * ** / // %
# print (( 30//27 ) * 10)
# print(5%2 == 1)

# print("🥶🫥")

# isEven = (x is 2 == 0)
# #isEven = (1 ==0)
# #is Even = false
# print (isEven) # True? False?

# myVar = 10

# # Data Structures
# #         0,1,2,3,4,5,6,7,8,9
# myList = [1,2,3,4,5,6,7,8,9,10]


# print(myList[3])


# # Loops
# while x < 10:
#     print("hi")
#     x = x + 1
    
# for i in range(10):
#     print("ey")
# # for

# # int, float, bool, string, char,...
# myvar = 12

# print(5//2)

# myfloat = 12.5

# mybool = True

# mystring1 = "hello"

# mystring2 = "hello"


# print(myvar)

# ## Conditionals
# x=7
# if 5 < x or myvar ==12:
#     print (":p")
# # and: both sides MUST be True
# # or: either can be True
# # xor: only one is allowed to be true 

# #comparison operators: < > == <= >=
# # not 

# print(( 4 < 5 ))
# print(not( 4 < 5 ))

# # Arithmetric Operators: + - * ** / // %
# print (( 30//27 ) * 10)
# print(5%2 == 1)

# print("🥶🫥")

# isEven = (x is 2 == 0)
# #isEven = (1 ==0)
# #is Even = false
# print (isEven) # True? False?

# myVar = 10

# # Data Structures
# #         0,1,2,3,4,5,6,7,8,9
# myList = [1,2,3,4,5,6,7,8,9,10]


# print(myList[3])


# # Loops
# while x < 10:
#     print("hi")
#     x = x + 1
    
# for i in range(10):
#     print("ey")
# # for

# print("asdf")

# # 1) Variables + types
# # Name tag
#     # Create variables: first_name, last_name, age.
#     # Print: Hi, I'm FIRST LAST and I'm AGE years old.
# first_name='mia'
# last_name =" lee"
# age = "14"

# print("Hi "+"there")
# print("Hi " + "there")

# # print("Hi, I'm " + first_name + last_name + " and I'm "+ age + " years old.")
# print(f"Hi, I'm {first_name} {last_name} and I'm {age} years old.")
# # Reassign
#     # Set age = age + 1 then print the new age.

# age = 1
# age = age + 1
# age += 1
# print(age)

# # age
# # String vs number
#     # Make age_str = "12" and age_num = 12.
#     # Try age_str + 1 (observe error), then fix it using int(age_str).

# age_str = "12"
# age_num = 12
# print(age_str + "1")

# # 2) Arithmetic operators

# # Calculator
#     # Given a = 13, b = 5, print:
#         # a + b, a - b, a * b, a / b

# a = 13
# b = 5

#         # a // b (integer division)
# print(a // b)
#         # a % b (remainder)
# print(a % b)
#         # a ** b (power)
# print(a ** b)


# # Minutes to hours
#     # Given minutes = 135, compute hours and leftover minutes.
# minutes = 135

# hours = minutes // 60
# leftover_minutes = minutes % 60
# print(f"{minutes} minutes is {hours} hours and {leftover_minutes} minutes")


# # Change maker
#     # Given cents (like 289), compute dollars and remaining cents.
# cents = 289
# dollars = cents // 100
# remaining_cents = cents % 100
# print(f"{cents} cents is {dollars} dollars and {remaining_cents} cents")

name = input("What is your name? ")
print(f"Hello, {name}!")


command = input("How long do you want me to say happy birthday?: ")

try:
    minutes = float(command)
except ValueError:
    print("Please enter a valid number.")

print("Hi")