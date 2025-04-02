@test "prints Hello, World!" {
  run oscript ./index.os
  expected="Hello, World!"
  diff <(echo "$expected") <(echo "$output")
}
