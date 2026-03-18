<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class DangKyRequest extends FormRequest
{

    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'ho_ten'          => 'required|string|max:150',
            'email'           => 'required|email|unique:nguoi_dungs,email|max:255',
            'password'        => 'required|min:6|max:255|confirmed',
            'so_dien_thoai'   => 'nullable|string|max:20',
            'ky_nang_ids'     => 'nullable|array',
            'ky_nang_ids.*'   => 'exists:ky_nangs,id',
            'ky_nang_khac'    => 'nullable|array',
            'ky_nang_khac.*'  => 'required|string|max:100',
            'khu_vuc_ids'     => 'nullable|array',
            'khu_vuc_ids.*'   => 'exists:khu_vucs,id',
            'khu_vuc_khac'    => 'nullable|array',
            'khu_vuc_khac.*'  => 'required|string|max:150',
        ];
    }

    public function messages()
    {
        return [
            'ho_ten.required'        => 'Họ tên không được để trống.',
            'ho_ten.max'             => 'Họ tên không được quá 150 ký tự.',
            'email.required'         => 'Email không được để trống.',
            'email.email'            => 'Email không đúng định dạng.',
            'email.unique'           => 'Email đã tồn tại trong hệ thống.',
            'email.max'              => 'Email không được quá 255 ký tự.',
            'password.required'      => 'Mật khẩu không được để trống.',
            'password.min'           => 'Mật khẩu phải có ít nhất 6 ký tự.',
            'password.max'           => 'Mật khẩu không được quá 255 ký tự.',
            'password.confirmed'     => 'Xác nhận mật khẩu không khớp.',
            'so_dien_thoai.max'      => 'Số điện thoại không được quá 20 ký tự.',
            'ky_nang_ids.array'      => 'Kỹ năng phải là danh sách.',
            'ky_nang_ids.*.exists'   => 'Kỹ năng không hợp lệ.',
            'ky_nang_khac.array'     => 'Kỹ năng khác phải là danh sách.',
            'ky_nang_khac.*.required'=> 'Vui lòng nhập kỹ năng khác.',
            'ky_nang_khac.*.max'     => 'Kỹ năng khác không được quá 100 ký tự.',
            'khu_vuc_ids.array'      => 'Khu vực phải là danh sách.',
            'khu_vuc_ids.*.exists'   => 'Khu vực không hợp lệ.',
            'khu_vuc_khac.array'     => 'Khu vực khác phải là danh sách.',
            'khu_vuc_khac.*.required'=> 'Vui lòng nhập khu vực khác.',
            'khu_vuc_khac.*.max'     => 'Khu vực khác không được quá 150 ký tự.',
        ];
    }
}
