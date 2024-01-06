# odin-mastermind

Mastermind created as part of The Odin Project.

This implementation allows the human to choose to be either the code breaker
or the code setter. Enter codes using the first letter of each desired color, e.g. for "Reg Green Purple White" type "RGPW". Input is case insensitive and any letters typed after a valid code sequence are ignored.

Pieces are displayed using emojis. For those who don't have emojis available,
this can be changed to letter display by changing the declaration at the top of the file:
```ruby
PIECE_TYPE = 0
```
To read:
```ruby
PIECE_TYPE = 1
```

The computer uses a brute force calculation to guess the code, where it checks every possible code against the feedback received so far. If the code could possibly be correct given all the guesses and feedback on the board, it is kept as a possibility. Otherwise it is discarded. The selection of code from the list of viable codes is random, as is the first guess. The computer provides feedback to the player on how many viable guesses remain and what those guesses are. Typically the computer guesses the correct code within approx. 5 turns using this method.

There are several instances of the DRY principle being broken pretty heavily due to my lack of OOP knowledge! However I think this is a good place to stop for this one.