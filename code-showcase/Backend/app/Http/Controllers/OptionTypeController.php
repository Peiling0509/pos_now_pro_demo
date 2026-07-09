<?php

namespace App\Http\Controllers;

use App\Models\OptionType;
use Illuminate\Http\Request;

class OptionTypeController extends Controller
{
    public function index()
    {
        return OptionType::with('options')->get();
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string',
        ]);

        return OptionType::create($validated);
    }

    public function show(OptionType $optionType)
    {
        return $optionType->load('options');
    }

    public function update(Request $request, OptionType $optionType)
    {
        $validated = $request->validate([
            'name' => 'string',
        ]);

        $optionType->update($validated);
        return $optionType;
    }

    public function destroy(OptionType $optionType)
    {
        $optionType->delete();
        return response()->json(['message' => 'Deleted']);
    }
}
