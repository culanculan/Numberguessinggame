#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read -r USERNAME || exit 0
SQL_USERNAME=${USERNAME//\'/\'\'}

USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$SQL_USERNAME'")

if [[ -z $USER_ID ]]; then
	INSERT_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$SQL_USERNAME') RETURNING user_id")
	USER_ID=$(echo "$INSERT_RESULT" | head -n 1)
	echo "Welcome, $USERNAME! It looks like this is your first time here."
else
	GAMES_PLAYED=$($PSQL "SELECT COUNT(*) FROM games WHERE user_id=$USER_ID")
	BEST_GAME=$($PSQL "SELECT MIN(guesses) FROM games WHERE user_id=$USER_ID")
	BEST_GAME=${BEST_GAME:-0}
	echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
NUMBER_OF_GUESSES=1

echo "Guess the secret number between 1 and 1000:"
read -r GUESS || exit 0

while [[ $GUESS != $SECRET_NUMBER ]]; do
	if [[ ! $GUESS =~ ^-?[0-9]+$ ]]; then
		echo "That is not an integer, guess again:"
	else
		if [[ $GUESS == -* ]]; then
			GUESS_NUMBER=$((-10#${GUESS#-}))
		else
			GUESS_NUMBER=$((10#$GUESS))
		fi

		if (( GUESS_NUMBER > SECRET_NUMBER )); then
			echo "It's lower than that, guess again:"
		else
			echo "It's higher than that, guess again:"
		fi
	fi

	read -r GUESS || exit 0
	((NUMBER_OF_GUESSES++))
done

$PSQL "INSERT INTO games(user_id, guesses) VALUES($USER_ID, $NUMBER_OF_GUESSES)" > /dev/null
echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"