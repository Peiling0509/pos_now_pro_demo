<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class LoginController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'name' => 'required|string',
            'password' => 'nullable|string',
            'pin' => 'nullable|digits:6', // 6 digit pin optional
        ]);

        // Must provide either password or pin
        if (!$request->password && !$request->pin) {
            return response()->json([
                'status' => false,
                'message' => 'Password or PIN required'
            ], 422);
        }

        // Find user
        $user = User::where('name', $request->name)->first();

        if (!$user) {
            return response()->json([
                'status' => false,
                'message' => 'Invalid name or credentials'
            ], 401);
        }

        // Check password OR PIN
        $passwordValid = $request->password && Hash::check($request->password, $user->password);
        $pinValid = $request->pin && Hash::check($request->pin, $user->pin_code);

        if (!$passwordValid && !$pinValid) {
            return response()->json([
                'status' => false,
                'message' => 'Invalid name or credentials'
            ], 401);
        }

        $user->tokens()->delete();

        // Create a brand new token for THIS device
        $token = $user->createToken('pos-device')->plainTextToken;

        return response()->json([
            'status' => true,
            'message' => 'Login successful',
            'data' => [
                'user' => $user,
                'token' => $token,
            ]
        ], 200);
    }


    public function logout(Request $request)
    {
        $request->user()->tokens()->delete(); // revoke all tokens

        return response()->json([
            'status' => true,
            'message' => 'Logout successful',
        ]);
    }
}
