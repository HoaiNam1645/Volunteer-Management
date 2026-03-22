<template>
	<div class="overlay toggle-icon"></div>
	<footer class="site-footer">
		<div class="footer-main">
			<div class="container">
				<div class="row g-4">
					<!-- Liên kết -->
					<div class="col-lg-2 col-md-6">
						<h6 class="text-dark fw-bold mb-3">{{ $t('footer.links') }}</h6>
						<ul class="list-unstyled footer-links">
							<li><router-link to="/">{{ $t('footer.home') }}</router-link></li>
							<li><router-link to="/danh-sach-chien-dich">{{ $t('footer.campaigns') }}</router-link></li>
							<li><a href="#">{{ $t('footer.aboutUs') }}</a></li>
						</ul>
					</div>
					<!-- Hỗ trợ -->
					<div class="col-lg-2 col-md-6">
						<h6 class="text-dark fw-bold mb-3">{{ $t('footer.support') }}</h6>
						<ul class="list-unstyled footer-links">
							<li><a href="#">{{ $t('footer.userGuide') }}</a></li>
							<li><a href="#">{{ $t('footer.faq') }}</a></li>
							<li><a href="#">{{ $t('footer.privacy') }}</a></li>
							<li><a href="#">{{ $t('footer.terms') }}</a></li>
						</ul>
					</div>
					<!-- Liên hệ -->
					<div class="col-lg-2 col-md-6">
						<h6 class="text-dark fw-bold mb-3">{{ $t('footer.contact') }}</h6>
						<ul class="list-unstyled footer-contact">
							<li>
								<i class="fa-solid fa-location-dot me-2 text-primary"></i>
								<span>101 Ỷ Lan Nguyên Phi, Hoà Cường Bắc, Hải Châu, Đà Nẵng, Việt Nam</span>
							</li>
							<li>
								<i class="fa-solid fa-phone me-2 text-primary"></i>
								<span>033 375 0444</span>
							</li>
							<li>
								<i class="fa-solid fa-envelope me-2 text-primary"></i>
								<span>contact@vms-ai.vn</span>
							</li>
						</ul>
					</div>
					<!-- Google Map -->
					<div class="col-lg-6 col-md-12">
						<h6 class="text-dark fw-bold mb-3">{{ $t('footer.map') }}</h6>
						<div class="footer-map">
							<iframe
								src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d16602.381204442907!2d108.21430882950318!3d16.040812587441863!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x314219ff7cf50bfd%3A0xa08a53c763cd81a!2sMay%20cafe%20%26%20apartment!5e1!3m2!1svi!2s!4v1772682000176!5m2!1svi!2s"
								width="100%"
								height="200"
								style="border:0; border-radius:10px;"
								allowfullscreen=""
								loading="lazy"
								referrerpolicy="no-referrer-when-downgrade">
							</iframe>
						</div>
					</div>
				</div>
			</div>
		</div>

	</footer>
</template>
<script>
export default {

}
</script>
<style scoped>
.site-footer {
	position: relative;
	z-index: 3;
}

.footer-main {
	background: #ffffff;
	padding: 50px 0 30px;
	border-top: 1px solid #e9ecef;
}

.footer-logo-icon {
	width: 36px;
	height: 36px;
	border-radius: 10px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 18px;
}

.btn-social {
	width: 34px;
	height: 34px;
	padding: 0;
	display: flex;
	align-items: center;
	justify-content: center;
	border-radius: 8px;
	font-size: 14px;
	color: #6c757d;
	border-color: #dee2e6;
}

.btn-social:hover {
	background: #0d6efd;
	border-color: #0d6efd;
	color: white;
}

.footer-links li {
	margin-bottom: 8px;
}

.footer-links a {
	color: #6c757d;
	text-decoration: none;
	font-size: 14px;
	transition: color 0.2s ease;
}

.footer-links a:hover {
	color: #0d6efd;
}

.footer-contact li {
	display: flex;
	align-items: flex-start;
	margin-bottom: 12px;
	color: #6c757d;
	font-size: 14px;
}

.footer-contact li i {
	margin-top: 3px;
	min-width: 20px;
}

.footer-bottom {
	background: #f8f9fa;
	padding: 20px 0;
}
</style>
