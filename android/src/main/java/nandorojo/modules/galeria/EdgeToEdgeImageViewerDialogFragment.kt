package nandorojo.modules.galeria

import android.app.Dialog
import android.content.Context
import android.content.DialogInterface
import android.graphics.Color
import android.graphics.PorterDuff
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.ImageButton
import android.widget.ImageView
import android.widget.LinearLayout
import androidx.appcompat.widget.PopupMenu
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.lifecycle.ViewModelProvider
import androidx.viewpager2.widget.ViewPager2
import com.github.iielse.imageviewer.ImageViewerActionViewModel
import com.github.iielse.imageviewer.ImageViewerDialogFragment

/**
 * Subclass of [ImageViewerDialogFragment] used by Galeria.
 *
 * Responsibilities:
 *   1. Present an edge-to-edge dialog with the system bars colored to match the light/dark theme.
 *   2. Forward the dialog's onDismiss to [onDismissCallback].
 *   3. Programmatically overlay a header toolbar at the top containing a close button and custom action buttons.
 */
class EdgeToEdgeImageViewerDialogFragment(
    private val isAppearanceLightSystemBars: Boolean?,
    private val onDismissCallback: () -> Unit,
    private val headerItems: List<Map<String, Any>>?,
    private val onHeaderActionCallback: (buttonId: String, menuItemId: String?, currentIndex: Int) -> Unit,
) : ImageViewerDialogFragment() {
    private var hasDismissed = false

    private val actionViewModel: ImageViewerActionViewModel by lazy {
        ViewModelProvider(requireActivity()).get(ImageViewerActionViewModel::class.java)
    }

    private fun triggerDismiss() {
        if (!hasDismissed) {
            hasDismissed = true
            onDismissCallback()
        }
    }

    override fun onCreateDialog(savedInstanceState: Bundle?): Dialog {
        if (isAppearanceLightSystemBars == null) {
            return super.onCreateDialog(savedInstanceState)
        }
        return Dialog(requireActivity(), R.style.Theme_FullScreenDialog).apply {
            setCanceledOnTouchOutside(true)

            window?.let {
                WindowCompat.setDecorFitsSystemWindows(it, false)

                WindowInsetsControllerCompat(it, it.decorView).run {
                    isAppearanceLightStatusBars = isAppearanceLightSystemBars
                    isAppearanceLightNavigationBars = isAppearanceLightSystemBars
                }
            }
        }
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val context = requireContext()
        val viewPager = findViewPager2(view)

        if (headerItems != null && view is ViewGroup) {
            val toolbar = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL

                val statusBarHeight = getStatusBarHeight(context)
                setPadding(dpToPx(16), statusBarHeight + dpToPx(8), dpToPx(16), dpToPx(8))

                layoutParams = ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT
                )
            }

            // 1. Close Button on the left
            val closeButton = ImageButton(context).apply {
                setImageResource(android.R.drawable.ic_menu_close_clear_cancel)
                setBackgroundColor(Color.TRANSPARENT)
                scaleType = ImageView.ScaleType.FIT_CENTER
                val padding = dpToPx(12)
                setPadding(padding, padding, padding, padding)
                setColorFilter(Color.WHITE, PorterDuff.Mode.SRC_IN)
                layoutParams = LinearLayout.LayoutParams(dpToPx(48), dpToPx(48))
                setOnClickListener {
                    actionViewModel.dismiss()
                }
            }
            toolbar.addView(closeButton)

            // 2. Spacer in the middle
            val spacer = View(context).apply {
                layoutParams = LinearLayout.LayoutParams(0, 0, 1f)
            }
            toolbar.addView(spacer)

            // 3. Header Action Buttons on the right
            val rightContainer = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
            }

            for (item in headerItems) {
                val buttonId = item["id"] as? String ?: continue
                val iconName = item["icon"] as? String ?: ""
                val isMenu = item["isMenu"] as? Boolean ?: false

                val actionButton = ImageButton(context).apply {
                    setBackgroundColor(Color.TRANSPARENT)
                    scaleType = ImageView.ScaleType.FIT_CENTER
                    val padding = dpToPx(12)
                    setPadding(padding, padding, padding, padding)
                    setColorFilter(Color.WHITE, PorterDuff.Mode.SRC_IN)

                    val drawableRes = when (iconName) {
                        "square.and.arrow.up" -> android.R.drawable.ic_menu_share
                        "ellipsis", "ellipsis.circle" -> androidx.appcompat.R.drawable.abc_ic_menu_overflow_material
                        "square.and.arrow.down" -> android.R.drawable.ic_menu_save
                        "trash" -> android.R.drawable.ic_menu_delete
                        else -> android.R.drawable.ic_menu_help
                    }
                    setImageResource(drawableRes)

                    val params = LinearLayout.LayoutParams(
                        dpToPx(48),
                        dpToPx(48)
                    ).apply {
                        marginStart = dpToPx(8)
                    }
                    layoutParams = params

                    setOnClickListener {
                        val currentIndex = viewPager?.currentItem ?: 0

                        if (isMenu) {
                            val menuItems = item["menuItems"] as? List<Map<String, Any>>
                            if (menuItems != null && menuItems.isNotEmpty()) {
                                val popup = PopupMenu(context, this)
                                menuItems.forEachIndexed { idx, mItem ->
                                    val mLabel = mItem["label"] as? String ?: ""
                                    popup.menu.add(0, idx, idx, mLabel)
                                }
                                popup.setOnMenuItemClickListener { menuItem ->
                                    val selectedItem = menuItems[menuItem.itemId]
                                    val selectedId = selectedItem["id"] as? String ?: ""
                                    onHeaderActionCallback(buttonId, selectedId, currentIndex)
                                    true
                                }
                                popup.show()
                            }
                        } else {
                            onHeaderActionCallback(buttonId, null, currentIndex)
                        }
                    }
                }
                rightContainer.addView(actionButton)
            }
            toolbar.addView(rightContainer)

            view.addView(toolbar)
        }
    }

    private fun findViewPager2(view: View): ViewPager2? {
        if (view is ViewPager2) {
            return view
        }
        if (view is ViewGroup) {
            for (i in 0 until view.childCount) {
                val child = view.getChildAt(i)
                val result = findViewPager2(child)
                if (result != null) {
                    return result
                }
            }
        }
        return null
    }

    private fun dpToPx(dp: Int): Int {
        val density = resources.displayMetrics.density
        return (dp * density).toInt()
    }

    private fun getStatusBarHeight(context: Context): Int {
        var statusBarHeight = 0
        val resourceId = context.resources.getIdentifier("status_bar_height", "dimen", "android")
        if (resourceId > 0) {
            statusBarHeight = context.resources.getDimensionPixelSize(resourceId)
        }
        return statusBarHeight
    }

    override fun onDismiss(dialog: DialogInterface) {
        super.onDismiss(dialog)
        triggerDismiss()
    }
}

