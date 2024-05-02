can get_item_by_label(widget: any, item_type: str, label: str) -> any {
    return [item  for item in widget.get(item_type) if item.label == label][0];
}
