extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    var scene = load("res://shop.tscn").instantiate()
    root.add_child(scene)
    await process_frame
    await process_frame
    await process_frame
    var image = root.get_texture().get_image()
    var result = image.save_png("res://.ignore/shop-layout-check.png")
    print("SHOP_CAPTURE: ", image.get_size(), " result=", result)
    scene.queue_free()
    quit()
