.PHONY: release

release:
	@if [ -z "$(word 2,$(MAKECMDGOALS))" ]; then \
		echo "❌ 버전을 입력하세요."; \
		echo "예: make release 1.0.0"; \
		exit 1; \
	fi
	bash Scripts/release.sh $(word 2,$(MAKECMDGOALS))

%:
	@: