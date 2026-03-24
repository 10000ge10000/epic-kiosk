# -*- coding: utf-8 -*-
"""Epic 认证服务（Cookie-Only）"""

from enum import Enum

from loguru import logger
from playwright.async_api import expect, Page

from settings import settings

URL_CLAIM = "https://store.epicgames.com/en-US/free-games"


class ErrorType(Enum):
    """登录与会话状态"""

    SUCCESS = "success"
    EULA_FAILED = "eula_failed"
    NETWORK_TIMEOUT = "network_timeout"
    COOKIE_INVALID = "cookie_invalid"
    UNKNOWN = "unknown"


class EpicAuthorization:
    """仅 Cookie 会话认证。"""

    def __init__(self, page: Page):
        self.page = page

    async def _handle_eula_correction(self) -> tuple[bool, ErrorType]:
        """处理 EULA 修正页面（如出现）。"""
        current_url = self.page.url

        if "correction/eula" not in current_url and "corrective=" not in current_url:
            return False, ErrorType.SUCCESS

        logger.warning("⚠️ 检测到 EULA 修正页面，尝试自动接受协议...")

        try:
            await self.page.wait_for_load_state("networkidle")
            await self.page.wait_for_timeout(2000)

            accept_selectors = [
                "#accept",
                "button#accept",
                "//button[@aria-label='接受']",
                "//button[@aria-label='Accept']",
                "//button[@type='submit']",
                "//button[normalize-space(text())='接受']",
                "//button[normalize-space(text())='Accept']",
                "//button[contains(@class, 'MuiButton-containedPrimary')]",
            ]

            for selector in accept_selectors:
                try:
                    btn = self.page.locator(selector).first
                    await expect(btn).to_be_visible(timeout=3000)
                    await btn.scroll_into_view_if_needed()
                    await btn.click(force=True, timeout=5000)
                    await self.page.wait_for_load_state("networkidle", timeout=30000)
                    await self.page.wait_for_timeout(1500)

                    new_url = self.page.url
                    if "correction/eula" not in new_url and "corrective=" not in new_url:
                        logger.success("✅ EULA 协议已接受")
                        return True, ErrorType.SUCCESS
                except Exception:
                    continue

            logger.error("❌ 未能自动处理 EULA 页面")
            return False, ErrorType.EULA_FAILED
        except Exception as exc:
            logger.error(f"❌ EULA 处理异常: {exc}")
            return False, ErrorType.EULA_FAILED

    async def invoke(self) -> ErrorType:
        """执行 Cookie-Only 鉴权：只接受已登录会话，不做账号密码登录。"""

        if not settings.COOKIE_ONLY_MODE:
            logger.warning("⚠️ 当前工程已精简为 Cookie-Only，建议设置 COOKIE_ONLY_MODE=true")

        for attempt in range(3):
            logger.info(f"🔄 Cookie 会话检测 [{attempt + 1}/3]")
            try:
                await self.page.goto(URL_CLAIM, wait_until="domcontentloaded")
            except Exception as exc:
                logger.warning(f"页面加载失败: {exc}")
                if "timeout" in str(exc).lower():
                    return ErrorType.NETWORK_TIMEOUT
                continue

            await self.page.wait_for_timeout(2500)

            for _ in range(3):
                current_url = self.page.url
                if "correction/eula" in current_url or "corrective=" in current_url:
                    success, error_type = await self._handle_eula_correction()
                    if not success:
                        return error_type
                    await self.page.goto(URL_CLAIM, wait_until="domcontentloaded")
                    await self.page.wait_for_timeout(2000)
                else:
                    break

            try:
                status = await self.page.locator("//egs-navigation").get_attribute(
                    "isloggedin", timeout=15000
                )
            except Exception as exc:
                logger.error(f"❌ 获取登录状态失败: {exc}")
                if "timeout" in str(exc).lower():
                    return ErrorType.NETWORK_TIMEOUT
                return ErrorType.UNKNOWN

            if status == "true":
                logger.success("✅ Cookie 会话有效，已登录 Epic")
                return ErrorType.SUCCESS

            logger.error("❌ Cookie 无效或已过期，请先手动在浏览器登录并刷新会话目录")
            return ErrorType.COOKIE_INVALID

        logger.error("❌ 会话检测失败")
        return ErrorType.UNKNOWN
