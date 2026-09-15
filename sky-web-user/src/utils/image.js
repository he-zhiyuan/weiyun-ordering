import dishPlaceholder from '../assets/dish-placeholder.svg'

export const DISH_PLACEHOLDER = dishPlaceholder

export function onImageError(e) {
  e.target.onerror = null
  e.target.src = DISH_PLACEHOLDER
}
