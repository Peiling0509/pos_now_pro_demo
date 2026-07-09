<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;

class MenuUpdated implements ShouldBroadcastNow
{
    public function broadcastOn()
    {
        // Broadcast to a public channel all POS devices listen to
        return new Channel('pos-now-channel'); 
    }

    public function broadcastAs()
    {
        return 'menu.updated';
    }
}