<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class DangNhapRequest extends FormRequest
{

    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'email'    => 'required|email|exists:nguoi_dungs,email',
            'password' => 'required|min:6|max:255',
        ];
    }

    public function messages()
    {
        return [
            'email.required'    => 'Email không được để trống.',
            'email.email'       => 'Email không đúng định dạng.',
            'email.exists'      => 'Email không tồn tại trong hệ thống.',
            'password.required' => 'Mật khẩu không được để trống.',
            'password.min'      => 'Mật khẩu phải có ít nhất 6 ký tự.',
            'password.max'      => 'Mật khẩu không được quá 255 ký tự.',
        ];
    }
}
