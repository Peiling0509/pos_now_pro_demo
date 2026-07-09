<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow; // IMPORTANT
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

// "ShouldBroadcastNow" means send immediately, don't wait for a queue worker
class TableUpdated implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $tableId;
    public $status;

    public function __construct($tableId, $status)
    {
        $this->tableId = $tableId;
        $this->status = $status;
    }

    public function broadcastOn()
    {
        // This is the "Radio Channel" name
        return new Channel('pos-now-channel');
    }

    public function broadcastAs()
    {
        return 'table.updated';
    }
}