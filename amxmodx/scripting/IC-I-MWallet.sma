#include <amxmodx>
#include <VipModular>
#include <ModularWallet>

#pragma semicolon 1
#pragma compress 1

public stock const PluginName[] = "[VipM-I] MWallet";
public stock const PluginVersion[] = "1.0.0";
public stock const PluginAuthor[] = "ArKaNeMaN";
public stock const PluginURL[] = "t.me/arkaneman";

new const BUY_TYPE_NAME[] = "MWallet-Buy";
new const DEBIT_TYPE_NAME[] = "MWallet-Debit";
new const SET_TYPE_NAME[] = "MWallet-Set";

public VipM_IC_OnInitTypes() {
    register_plugin(PluginName, PluginVersion, PluginAuthor);
    MWallet_Init();

    VipM_IC_RegisterType(SET_TYPE_NAME);
    VipM_IC_RegisterTypeEvent(SET_TYPE_NAME, ItemType_OnRead, "@OnSetRead");
    VipM_IC_RegisterTypeEvent(SET_TYPE_NAME, ItemType_OnGive, "@OnSetGive");

    VipM_IC_RegisterType(DEBIT_TYPE_NAME);
    VipM_IC_RegisterTypeEvent(DEBIT_TYPE_NAME, ItemType_OnRead, "@OnDebitRead");
    VipM_IC_RegisterTypeEvent(DEBIT_TYPE_NAME, ItemType_OnGive, "@OnDebitGive");

    VipM_IC_RegisterType(BUY_TYPE_NAME);
    VipM_IC_RegisterTypeEvent(BUY_TYPE_NAME, ItemType_OnRead, "@OnBuyRead");
    VipM_IC_RegisterTypeEvent(BUY_TYPE_NAME, ItemType_OnGive, "@OnBuyGive");
}

@OnSetRead(const JSON:itemJson, Trie:p) {
    if (!json_object_has_value(itemJson, "Currency", JSONString)) {
        VipM_Json_LogForFile(itemJson, "WARNING", "Parameter `Currency` required for `%s` item type.", SET_TYPE_NAME);
        return VIPM_STOP;
    }

    if (!json_object_has_value(itemJson, "Amount", JSONNumber)) {
        VipM_Json_LogForFile(itemJson, "WARNING", "Parameter `Amount` required for `%s` item type.", SET_TYPE_NAME);
        return VIPM_STOP;
    }

    new currencyName[MWALLET_CURRENCY_MAX_NAME_LEN];
    json_object_get_string(itemJson, "Currency", currencyName, charsmax(currencyName));
    new T_Currency:currency = MWallet_Currency_Find(currencyName);
    if (currency == Invalid_Currency) {
        VipM_Json_LogForFile(itemJson, "WARNING", "Currency `%s` not found.", currencyName);
        return VIPM_STOP;
    }
    TrieSetCell(p, "Currency", currency);

    TrieSetCell(p, "Amount", json_object_get_real(itemJson, "Amount"));

    return VIPM_CONTINUE;
}

@OnSetGive(const playerIndex, const Trie:p) {
    new T_Currency:currency = VipM_Params_GetCell(p, "Currency");
    new Float:amount = VipM_Params_GetFloat(p, "Amount");

    return MWallet_Currency_Set(currency, playerIndex, amount) ? VIPM_CONTINUE : VIPM_STOP;
}

@OnDebitRead(const JSON:itemJson, Trie:p) {
    if (!json_object_has_value(itemJson, "Currency", JSONString)) {
        VipM_Json_LogForFile(itemJson, "WARNING", "Parameter `Currency` required for `%s` item type.", DEBIT_TYPE_NAME);
        return VIPM_STOP;
    }

    if (!json_object_has_value(itemJson, "Amount", JSONNumber)) {
        VipM_Json_LogForFile(itemJson, "WARNING", "Parameter `Amount` required for `%s` item type.", DEBIT_TYPE_NAME);
        return VIPM_STOP;
    }

    new currencyName[MWALLET_CURRENCY_MAX_NAME_LEN];
    json_object_get_string(itemJson, "Currency", currencyName, charsmax(currencyName));
    new T_Currency:currency = MWallet_Currency_Find(currencyName);
    if (currency == Invalid_Currency) {
        VipM_Json_LogForFile(itemJson, "WARNING", "Currency `%s` not found.", currencyName);
        return VIPM_STOP;
    }
    TrieSetCell(p, "Currency", currency);

    TrieSetCell(p, "Amount", json_object_get_real(itemJson, "Amount"));

    return VIPM_CONTINUE;
}

@OnDebitGive(const playerIndex, const Trie:p) {
    new T_Currency:currency = VipM_Params_GetCell(p, "Currency");
    new Float:amount = VipM_Params_GetFloat(p, "Amount");

    return MWallet_Currency_Debit(currency, playerIndex, amount) ? VIPM_CONTINUE : VIPM_STOP;
}

@OnBuyRead(const JSON:itemJson, Trie:p) {
    if (!json_object_has_value(itemJson, "Currency", JSONString)) {
        VipM_Json_LogForFile(itemJson, "WARNING", "Parameter `Currency` required for `%s` item type.", BUY_TYPE_NAME);
        return VIPM_STOP;
    }

    if (!json_object_has_value(itemJson, "Cost", JSONNumber)) {
        VipM_Json_LogForFile(itemJson, "WARNING", "Parameter `Cost` required for `%s` item type.", BUY_TYPE_NAME);
        return VIPM_STOP;
    }

    if (!json_object_has_value(itemJson, "Items")) {
        VipM_Json_LogForFile(itemJson, "WARNING", "Parameter `Items` required for `%s` item type.", BUY_TYPE_NAME);
        return VIPM_STOP;
    }

    new currencyName[MWALLET_CURRENCY_MAX_NAME_LEN];
    json_object_get_string(itemJson, "Currency", currencyName, charsmax(currencyName));
    new T_Currency:currency = MWallet_Currency_Find(currencyName);
    if (currency == Invalid_Currency) {
        VipM_Json_LogForFile(itemJson, "WARNING", "Currency `%s` not found.", currencyName);
        return VIPM_STOP;
    }
    TrieSetCell(p, "Currency", currency);

    TrieSetCell(p, "Cost", json_object_get_real(itemJson, "Cost"));
    TrieSetCell(p, "Items", VipM_IC_JsonGetItems(json_object_get_value(itemJson, "Items")));

    return VIPM_CONTINUE;
}

@OnBuyGive(const playerIndex, const Trie:p) {
    new T_Currency:currency = VipM_Params_GetCell(p, "Currency");
    new Float:cost = VipM_Params_GetFloat(p, "Cost");
    new Array:items = VipM_Params_GetArr(p, "Items");

    if (!MWallet_Currency_IsEnough(currency, playerIndex, cost)) {
        return VIPM_STOP;
    }

    // Если по какой-то причине предметы не будут выданы, средства не спишутся.
    if (VipM_IC_GiveItems(playerIndex, items)) {
        MWallet_Currency_Credit(currency, playerIndex, cost);
        return VIPM_STOP;
    }

    return VIPM_CONTINUE;
}
