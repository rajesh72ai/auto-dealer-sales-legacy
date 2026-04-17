package com.autosales.modules.agent.action;

public enum Tier {
    A("A", "Sales floor"),
    B("B", "Manager"),
    C("C", "Operator / batch"),
    D("D", "Chained");

    private final String code;
    private final String label;

    Tier(String code, String label) {
        this.code = code;
        this.label = label;
    }

    public String getCode() { return code; }
    public String getLabel() { return label; }
}
