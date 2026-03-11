<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>

    @auth
     <p>Congrats you are logged in.</p>
    @else
    <div style = "border: 3px solid black;">
       <h1>Register</h1>
       <form action="/register" method="POST">
        @csrf
        <input type="text" name="name" id="name">
        <input type="email" name="email" id="email">
        <input type="password" name="password" id="password">
        <button type="submit">Register</button>
       </form>
    </div>
    @endauth
     
</body>
</html>