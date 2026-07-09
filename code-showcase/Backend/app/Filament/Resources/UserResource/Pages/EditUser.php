<?php

namespace App\Filament\Resources\UserResource\Pages;

use App\Filament\Resources\UserResource;
use App\Models\User;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditUser extends EditRecord
{
    protected static string $resource = UserResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make()
                ->hidden(function (User $record): bool {
                    if ($record->role !== 'admin') {
                        return false; 
                    }
                    return User::where('role', 'admin')->count() <= 1; 
                })
                ->before(function (Actions\DeleteAction $action, User $record) {
                    if ($record->role === 'admin' && User::where('role', 'admin')->count() <= 1) {
                        
                        \Filament\Notifications\Notification::make()
                            ->title(__('resource.admin_protected') ?? 'Action Denied')
                            ->body(__('resource.cannot_delete_all_admins') ?? 'You cannot delete the last remaining admin account.')
                            ->danger()
                            ->send();

                        $action->halt();
                    }
                }),
        ];
    }
}