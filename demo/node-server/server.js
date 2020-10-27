
const express = require('express')
const app = express()
const port = 3000

console.log("STARTING UP")
console.log(process.env)

app.get('/', (req, res) => {
  res.send('Hello World!')
})

app.listen(port, () => {
  console.log(`Example app listening at http://localhost:${port}`)
})

