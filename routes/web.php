<?php

use App\Http\Controllers\PostController;
use App\Http\Controllers\UserController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('home');
});

Route::post('/register', [UserController::class, 'register']);

Route::post('/logout', [UserController::class, 'logout']);

Route::post('/login', [UserController::class, 'login']);


Route::post('/create-post',[PostController::class, 'createPost']);