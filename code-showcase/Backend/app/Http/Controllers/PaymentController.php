<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\Payment;
use App\Models\Table;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;

class PaymentController extends Controller
{
    public function store(Request $request)
    {
        // 1. Validate Input
        $request->validate([
            'order_id' => 'required|exists:orders,id',
            'method'   => 'required|in:cash,spay,duitNow',
            // If cash, tendered_amount is required and must be numeric
            'tendered_amount' => 'required_if:method,cash|numeric|min:0',
        ]);

        DB::beginTransaction();

        try {
            $order = Order::findOrFail($request->order_id);

            // 2. Guard: Prevent double payment
            if ($order->status === 'paid') {
                return response()->json(['message' => 'Order is already paid.'], 400);
            }

            // 3. Determine Amounts
            $amountToPay = $order->total; // The bill amount
            $tendered = 0;
            $change = 0;

            if ($request->method === 'cash') {
                $tendered = $request->tendered_amount;
                
                // Check if cash is sufficient
                if ($tendered < $amountToPay) {
                    return response()->json([
                        'message' => 'Insufficient cash tendered.',
                        'shortage' => $amountToPay - $tendered
                    ], 422);
                }

                $change = $tendered - $amountToPay;
            } else {
                // For Digital (Spay/DuitNow), we assume exact payment
                $tendered = $amountToPay;
                $change = 0;
            }

            $padTime = $request->pad_time 
                ? \Carbon\Carbon::parse($request->pad_time) 
                : now();

            // 4. Create Payment Record
            $payment = Payment::create([
                'order_id'        => $order->id,
                'method'          => $request->method,
                'amount'          => $amountToPay,      // Amount covering the bill
                'tendered_amount' => $tendered,         // Actual money handed over
                'change_amount'   => $change,           // Change given back
                'created_at'      => $padTime,          // Force iPad time!
                'updated_at'      => $padTime,
            ]);

            // 5. Update Order Status
            $order->status = 'paid';
            $order->save();

            // 6. Free the Table (If Dine-in)
            if ($order->table_id) {
                Table::where('id', $order->table_id)->update(['status' => 'available']);
                // broadcast(new TableUpdated($order->table_id, 'available')); // Optional: Real-time event
            }

            DB::commit();

            if ($order->table_id) {
                event(new \App\Events\TableUpdated($order->table_id, 'available'));
            }

            return response()->json([
                'success' => true,
                'message' => 'Payment successful'
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Payment failed',
                'error' => $e->getMessage()
            ], 500);
        }
    }


    public function getByOrderId(Request $request)
    {
        $request->validate([
            'order_id' => 'required|exists:orders,id',
        ]);

        // 2. Fetch the payment using the validated request data
        $payment = Payment::where('order_id', $request->order_id)->first();

        if (!$payment) {
            return response()->json([
                'success' => false,
                'message' => 'Payment record not found for this order.'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $payment
        ], 200);
    }
}