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
     <form action="/logout" method="POST">
        @csrf
        <button type="submit">Logout</button>
     </form>
     <div style = "border: 3px solid black;">
      <h2>Create a New Post</h2>
      <form action="/create-post" method="POST">
        @csrf
        <input type="text" name="title" placeholder="post title">
        <textarea name="body" placeholder="body content..."></textarea>
        <button type="submit">Save Post</button>
      </form>
    </div>
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
    <div style = "border: 3px solid black;">
       <h1>Login</h1>
       <form action="/login" method="POST">
        @csrf
        <input type="text" name="loginname" placeholder="name">
        <input type="password" name="loginpassword" placeholder="password">
        <button type="submit">Login</button>
       </form>
    </div>
    @endauth
     
</body>
</html>