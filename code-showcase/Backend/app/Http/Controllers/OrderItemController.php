<?php

namespace App\Http\Controllers;

use App\Models\OrderItem;
use Illuminate\Http\Request;

class OrderItemController extends Controller
{
    /**
     * Display a listing of all order items.
     */
    public function index()
    {
        return response()->json([
            'success' => true,
            'data' => OrderItem::all(),
        ], 200);
    }

    /**
     * Store a newly created order item.
     */
    public function store(Request $request)
    {
        $request->validate([
            'order_id' => 'required|exists:orders,id',
            'menu_item_id' => 'required|exists:menu_items,id',
            'quantity' => 'required|integer|min:1',
            'price' => 'required|numeric|min:0',
        ]);

        $orderItem = OrderItem::create($request->only([
            'order_id',
            'menu_item_id',
            'quantity',
            'price',
        ]));

        return response()->json([
            'success' => true,
            'message' => 'Order item created successfully',
            'data' => $orderItem,
        ], 201);
    }

    /**
     * Display the specified order item.
     */
    public function show(OrderItem $orderItem)
    {
        return response()->json([
            'success' => true,
            'data' => $orderItem,
        ], 200);
    }

    /**
     * Update the specified order item.
     */
    public function update(Request $request, OrderItem $orderItem)
    {
        $request->validate([
            'order_id' => 'sometimes|exists:orders,id',
            'menu_item_id' => 'sometimes|exists:menu_items,id',
            'quantity' => 'sometimes|integer|min:1',
            'price' => 'sometimes|numeric|min:0',
        ]);

        $orderItem->update($request->only([
            'order_id',
            'menu_item_id',
            'quantity',
            'price',
        ]));

        return response()->json([
            'success' => true,
            'message' => 'Order item updated successfully',
            'data' => $orderItem,
        ], 200);
    }

    /**
     * Remove the specified order item.
     */
    public function destroy(OrderItem $orderItem)
    {
        $orderItem->delete();

        return response()->json([
            'success' => true,
            'message' => 'Order item deleted successfully',
        ], 200);
    }
}
