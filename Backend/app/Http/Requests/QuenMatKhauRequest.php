<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class QuenMatKhauRequest extends FormRequest
{

    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'email' => 'required|email|exists:nguoi_dungs,email',
        ];
    }

    public function messages()
    {
        return [
            'email.required' => 'Email không được để trống.',
            'email.email'    => 'Email không đúng định dạng.',
            'email.exists'   => 'Email không tồn tại trong hệ thống.',
        ];
    }
}
