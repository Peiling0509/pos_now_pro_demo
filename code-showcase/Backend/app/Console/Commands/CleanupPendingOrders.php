<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Order;
use App\Models\Table;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class CleanupPendingOrders extends Command
{
    // The command you will type in the terminal (or schedule)
    protected $signature = 'orders:cleanup-pending';

    // Description of what the command does
    protected $description = 'Delete pending orders from previous days and release their tables';

    public function handle()
    {
        $this->info('Starting cleanup of old pending orders...');

        // Find orders that are 'pending' and created BEFORE today
        $oldOrders = Order::with('orderItems')
            ->where('status', 'pending')
            ->whereDate('created_at', '<', Carbon::today())
            ->get();

        if ($oldOrders->isEmpty()) {
            $this->info('No old pending orders found. Everything is clean!');
            return;
        }

        DB::beginTransaction();

        try {
            $count = 0;

            foreach ($oldOrders as $order) {
                // 1. Release the table if the order has one
                if ($order->table_id) {
                    Table::where('id', $order->table_id)->update(['status' => 'available']);
                    event(new \App\Events\TableUpdated($order->table_id, 'available'));
                }

                // 2. Delete Order Items and Options (to prevent orphaned data)
                foreach ($order->orderItems as $item) {
                    $item->orderItemOptions()->delete();
                    $item->delete();
                }

                // 3. Delete the Order
                $order->delete();
                $count++;
            }

            DB::commit();
            $this->info("Successfully deleted {$count} old pending order(s) and released their tables.");

        } catch (\Exception $e) {
            DB::rollBack();
            $this->error('An error occurred during cleanup: ' . $e->getMessage());
        }
    }
}