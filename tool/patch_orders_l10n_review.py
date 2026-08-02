#!/usr/bin/env python3
"""Patch orders l10n from web message files + add missing keys."""

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WEB = ROOT / "web" / "src" / "messages"
DART = ROOT / "mobile" / "lib" / "core" / "l10n" / "translations.dart"
EN_DART = ROOT / "mobile" / "lib" / "core" / "l10n" / "translations_en.dart"

WEB_TO_MOBILE = {
    "newTitle": "ordersNewTitle",
    "editTitle": "ordersEditTitle",
    "detailTitle": "ordersDetailTitle",
    "tabToday": "ordersTabToday",
    "tabTomorrow": "ordersTabTomorrow",
    "tabAll": "ordersTabAll",
    "filterAll": "ordersFilterAll",
    "status_active": "ordersStatusActive",
    "status_delivered": "ordersStatusDelivered",
    "status_cancelled": "ordersStatusCancelled",
    "empty": "ordersEmpty",
    "emptyDescription": "ordersEmptyDesc",
    "paid": "ordersPaid",
    "unpaid": "ordersUnpaid",
    "partiallyPaid": "ordersPartiallyPaid",
    "deliverAction": "ordersDeliverAction",
    "deliverTitle": "ordersDeliverTitle",
    "remainingLabel": "ordersRemainingLabel",
    "paymentNowLabel": "ordersPaymentNowLabel",
    "fillAll": "ordersFillAll",
    "payLater": "ordersPayLater",
    "payLaterHint": "ordersPayLaterHint",
    "deliverConfirm": "ordersDeliverConfirm",
    "delivered": "ordersDelivered",
    "deliveredAt": "ordersDeliveredAt",
    "addPayment": "ordersAddPayment",
    "paymentAmountLabel": "ordersPaymentAmountLabel",
    "paymentDateLabel": "ordersPaymentDateLabel",
    "paymentNoteLabel": "ordersPaymentNoteLabel",
    "paymentAdded": "ordersPaymentAdded",
    "paymentExceeds": "ordersPaymentExceeds",
    "paymentsTitle": "ordersPaymentsTitle",
    "noPayments": "ordersNoPayments",
    "itemsTitle": "ordersItemsTitle",
    "productLabel": "ordersProductLabel",
    "addItem": "ordersAddItem",
    "noProducts": "ordersNoProducts",
    "unitPriceLabel": "ordersUnitPriceLabel",
    "customerTitle": "ordersCustomerTitle",
    "existingCustomer": "ordersExistingCustomer",
    "newCustomer": "ordersNewCustomer",
    "selectCustomer": "ordersSelectCustomer",
    "searchCustomer": "ordersSearchCustomer",
    "noCustomers": "ordersNoCustomers",
    "customerNameLabel": "ordersCustomerNameLabel",
    "deliveryTitle": "ordersDeliveryTitle",
    "deliveryDateLabel": "ordersDeliveryDateLabel",
    "deliveryTimeLabel": "ordersDeliveryTimeLabel",
    "otherDate": "ordersOtherDate",
    "advanceLabel": "ordersAdvanceLabel",
    "advanceExceeds": "ordersAdvanceExceeds",
    "remainingAfterAdvance": "ordersRemainingAfterAdvance",
    "totalBelowPaid": "ordersTotalBelowPaid",
    "noteLabel": "ordersNoteLabel",
    "notePlaceholder": "ordersNotePlaceholder",
    "created": "ordersCreated",
    "updated": "ordersUpdated",
    "cancelOrder": "ordersCancelOrder",
    "cancelTitle": "ordersCancelTitle",
    "cancelDescription": "ordersCancelDescription",
    "cancelledToast": "ordersCancelledToast",
    "deleteDescription": "ordersDeleteDescription",
    "deletedToast": "ordersDeletedToast",
    "orderNotFound": "ordersNotFound",
    "summaryPaid": "ordersSummaryPaid",
    "notActiveEdit": "ordersNotActiveEdit",
}

EXTRA = {
    "ordersSelectCustomerRequired": {
        "uz": "Mijozni tanlang",
        "uz_CYRL": "Мижозни танланг",
        "ru": "Выберите клиента",
        "kk": "Клиентті таңдаңыз",
        "ky": "Кардарды тандаңыз",
        "tr": "Müşteri seçin",
        "en": "Please select a customer",
    },
}

LOCALE_MAP = {
    "uz_CYRL": "uz-Cyrl.json",
    "kk": "kk.json",
    "ky": "ky.json",
    "ru": "ru.json",
    "tr": "tr.json",
    "en": "en.json",
    "uz": "uz.json",
}

UZ_CYRL_CUSTOMERS = {
    "customersTitle": "Мижозлар",
    "customersNewTitle": "Янги мижоз",
    "customersEditTitle": "Мижозни таҳрирлаш",
    "customersDetailTitle": "Мижоз",
    "customersEmpty": "Мижозлар йўқ",
    "customersEmptyDesc": "Бirinchi мижозингизни қўшинг",
    "customersCreated": "Мижоз қўшилди",
    "customersUpdated": "Мижоз янгиланди",
    "customersDeleted": "Мижоз ўчирилди",
    "customersDeleteTitle": "Мижоз ўчирилсинми?",
    "customersDeleteConfirm": "Мижоз тўлиқ ўчирилади. Давом etasizmi?",
    "customersNoteLabel": "Изoh",
    "customersNameLabel": "Исми",
    "customersOrdersHistory": "Заказлар тарixi",
    "customersSearchHint": "Исм ёки телефон бo'yicha qidirish",
    "customersCreateOrder": "Заказ яратиш",
    "customersNotFound": "Мижоз топилмади",
    "permManageOrders": "Заказлар",
    "permManageOrdersDesc": "Мижозлар ва заказларни бошqarish",
}


def dart_escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace("'", "\\'")


def load_orders(locale_file: str) -> dict[str, str]:
    data = json.loads((WEB / locale_file).read_text(encoding="utf-8"))
    orders = data.get("orders", {})
    out = {}
    for web_key, mobile_key in WEB_TO_MOBILE.items():
        if web_key in orders:
            out[mobile_key] = orders[web_key]
    return out


def patch_block(content: str, block_name: str, updates: dict[str, str]) -> str:
    for key, value in updates.items():
        escaped = dart_escape(value)
        pattern = rf"(\s+'{re.escape(key)}':\s)('(?:\\'|[^'])*'|\([^)]*\)|'[^']*')"
        replacement = rf"\1'{escaped}'"
        new_content, n = re.subn(pattern, replacement, content, count=1)
        if n == 0:
            # insert after ordersDeliverConfirm if new key
            insert_after = "'ordersDeliverConfirm'"
            if insert_after in content and key not in content:
                idx = content.find(insert_after)
                line_end = content.find("\n", idx)
                line = content[idx:line_end]
                val_part = line.split(":", 1)[1]
                indent = "    "
                new_line = f"\n{indent}'{key}': '{escaped}',"
                content = content[: line_end] + new_line + content[line_end :]
            else:
                print(f"WARN: could not patch {block_name}.{key}")
        else:
            content = new_content
    return content


def main() -> None:
    dart = DART.read_text(encoding="utf-8")
    en_dart = EN_DART.read_text(encoding="utf-8")

    for locale, web_file in LOCALE_MAP.items():
        orders = load_orders(web_file)
        block = f"_{locale}" if locale != "en" else None
        if locale == "uz_CYRL":
            orders.update(UZ_CYRL_CUSTOMERS)
        if locale in EXTRA["ordersSelectCustomerRequired"]:
            orders["ordersSelectCustomerRequired"] = EXTRA[
                "ordersSelectCustomerRequired"
            ][locale]

        if locale == "en":
            for k, v in orders.items():
                escaped = dart_escape(v)
                en_dart, n = re.subn(
                    rf"('{re.escape(k)}':\s)'(?:\\'|[^'])*'",
                    rf"\1'{escaped}'",
                    en_dart,
                    count=1,
                )
                if n == 0:
                    # append before closing brace - skip, handle manually
                    pass
            continue

        const_name = "_uzCyrl" if locale == "uz_CYRL" else f"_{locale}"
        # extract block between static const _xx = { and matching };
        m = re.search(rf"static const {const_name} = \{{", dart)
        if not m:
            print(f"SKIP block {const_name}")
            continue
        start = m.start()
        brace = 0
        i = m.end() - 1
        while i < len(dart):
            if dart[i] == "{":
                brace += 1
            elif dart[i] == "}":
                brace -= 1
                if brace == 0:
                    end = i + 1
                    break
            i += 1
        block_content = dart[start:end]
        patched = patch_block(block_content, const_name, orders)
        dart = dart[:start] + patched + dart[end:]

    # Fix ru typo explicitly
    dart = dart.replace(
        "'ordersUpdated': 'Зakаз обновлён'",
        "'ordersUpdated': 'Заказ обновлён'",
    )

    # Add getters if missing
    getters = """
  String get ordersDelivered => _t('ordersDelivered');
  String get ordersPaymentAdded => _t('ordersPaymentAdded');
  String get ordersSelectCustomerRequired => _t('ordersSelectCustomerRequired');
"""
    if "ordersDelivered =>" not in dart:
        dart = dart.replace(
            "  String get ordersDeliverConfirm => _t('ordersDeliverConfirm');",
            "  String get ordersDeliverConfirm => _t('ordersDeliverConfirm');"
            + getters,
        )

    DART.write_text(dart, encoding="utf-8")

    # Patch en dart for new keys + web sync
    en_orders = load_orders("en.json")
    en_orders["ordersSelectCustomerRequired"] = EXTRA["ordersSelectCustomerRequired"][
        "en"
    ]
    for k, v in en_orders.items():
        escaped = dart_escape(v)
        if f"'{k}':" in en_dart:
            en_dart = re.sub(
                rf"'{re.escape(k)}':\s'(?:\\'|[^'])*'",
                f"'{k}': '{escaped}'",
                en_dart,
                count=1,
            )
        else:
            en_dart = en_dart.replace(
                "  'ordersDeliverConfirm':",
                f"  'ordersDelivered': '{dart_escape(en_orders.get('ordersDelivered', 'Order delivered'))}',\n"
                f"  'ordersPaymentAdded': '{dart_escape(en_orders.get('ordersPaymentAdded', 'Payment added'))}',\n"
                f"  'ordersSelectCustomerRequired': '{dart_escape(en_orders['ordersSelectCustomerRequired'])}',\n"
                f"  'ordersDeliverConfirm':",
            )
    EN_DART.write_text(en_dart, encoding="utf-8")
    print("Done patching l10n")


if __name__ == "__main__":
    main()
