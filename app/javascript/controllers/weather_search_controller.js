import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["zipFields", "cityStateFields", "form", "zip", "city", "state"]

  connect() {
    // Ensure initial mode matches the checked radio
    const selected = this._selectedMode()
    this._updateVisibility(selected)

    // Wire up validation handlers for Bootstrap classes
    if (this.hasZipTarget) {
      this._zipInputHandler = this._validateZip.bind(this)
      this.zipTarget.addEventListener('input', this._zipInputHandler)
    }

    if (this.hasFormTarget) {
      this._formSubmitHandler = (event) => {
        // If ZIP mode and invalid zip, prevent submit and show invalid state
        if (this._selectedMode() === 'zip' && this.hasZipTarget && !this._isZipValid()) {
          this.zipTarget.classList.add('is-invalid')
          this.zipTarget.setAttribute('aria-invalid', 'true')
          // Ensure the aria-describedby points to the feedback element so screen readers announce it
          this.zipTarget.setAttribute('aria-describedby', 'zip-feedback')
          // Announce validation failure
          this._announceStatus('Please enter a valid 5-digit ZIP code.')
          event.preventDefault()
          event.stopPropagation()
          return
        }

        this._announceStatus('Searching for weather...')
      }
      this.formTarget.addEventListener('submit', this._formSubmitHandler)
    }

    // If a weather result is present on the page, reset the form inputs and announce
    const resultEl = document.getElementById('weather-result')
    if (resultEl) {
      this.resetForm()
      // Announce that results are available
      const locationName = resultEl.querySelector('h2') ? resultEl.querySelector('h2').innerText : 'Results available'
      this._announceStatus(`${locationName} — results are available.`)
    }
  }

  disconnect() {
    // Clean up listeners to avoid leaks
    if (this.hasZipTarget && this._zipInputHandler) {
      this.zipTarget.removeEventListener('input', this._zipInputHandler)
      this._zipInputHandler = null
    }
    if (this.hasFormTarget && this._formSubmitHandler) {
      this.formTarget.removeEventListener('submit', this._formSubmitHandler)
      this._formSubmitHandler = null
    }
  }

  modeChange(event) {
    const mode = event.target.value
    this._updateVisibility(mode)

    // Toggle aria-expanded on the radio that triggered the change
    if (event.target && event.target.id) {
      const zipRadio = this.element.querySelector('#mode_zip')
      const cityStateRadio = this.element.querySelector('#mode_city_state')
      if (zipRadio) zipRadio.setAttribute('aria-expanded', mode === 'zip')
      if (cityStateRadio) cityStateRadio.setAttribute('aria-expanded', mode === 'city_state')
    }

    // Manage focus for accessibility: focus the first focusable input in the visible group
    if (mode === 'zip' && this.hasZipTarget) {
      this.zipTarget.focus()
      this._announceStatus('ZIP code field focused.')
    } else if (mode === 'city_state') {
      if (this.hasCityTarget) {
        this.cityTarget.focus()
        this._announceStatus('City field focused.')
      }
    }
  }

  _selectedMode() {
    const checked = this.element.querySelector('input[name="mode"]:checked')
    return checked ? checked.value : 'zip'
  }

  _updateVisibility(mode) {
    if (mode === 'zip') {
      // show zip fields, hide city/state using Bootstrap utilities
      if (this.hasZipFieldsTarget) {
        this.zipFieldsTarget.classList.remove('d-none')
        this.zipFieldsTarget.setAttribute('aria-hidden', 'false')
      }
      if (this.hasCityStateFieldsTarget) {
        this.cityStateFieldsTarget.classList.add('d-none')
        this.cityStateFieldsTarget.setAttribute('aria-hidden', 'true')
      }
    } else {
      if (this.hasZipFieldsTarget) {
        this.zipFieldsTarget.classList.add('d-none')
        this.zipFieldsTarget.setAttribute('aria-hidden', 'true')
      }
      if (this.hasCityStateFieldsTarget) {
        this.cityStateFieldsTarget.classList.remove('d-none')
        this.cityStateFieldsTarget.setAttribute('aria-hidden', 'false')
      }
    }

    // Re-validate zip when visibility changes
    if (this.hasZipTarget) this._validateZip()
  }

  _isZipValid() {
    if (!this.hasZipTarget) return true
    const v = (this.zipTarget.value || '').trim()
    return /^\d{5}$/.test(v)
  }

  _validateZip() {
    if (!this.hasZipTarget) return
    const value = (this.zipTarget.value || '').trim()

    // Clear validation state when empty
    if (value === '') {
      this.zipTarget.classList.remove('is-valid', 'is-invalid')
      this.zipTarget.setAttribute('aria-invalid', 'false')
      // Remove describedby when empty
      this.zipTarget.removeAttribute('aria-describedby')
      return
    }

    if (this._isZipValid()) {
      this.zipTarget.classList.add('is-valid')
      this.zipTarget.classList.remove('is-invalid')
      this.zipTarget.setAttribute('aria-invalid', 'false')
      this.zipTarget.removeAttribute('aria-describedby')
    } else {
      this.zipTarget.classList.add('is-invalid')
      this.zipTarget.classList.remove('is-valid')
      this.zipTarget.setAttribute('aria-invalid', 'true')
      this.zipTarget.setAttribute('aria-describedby', 'zip-feedback')
    }
  }

  resetForm() {
    // Clear inputs so the form appears reset after a submit that returned results
    if (this.hasZipTarget) {
      this.zipTarget.value = ''
      this.zipTarget.classList.remove('is-valid', 'is-invalid')
      this.zipTarget.setAttribute('aria-invalid', 'false')
      this.zipTarget.removeAttribute('aria-describedby')
    }
    if (this.hasCityTarget) {
      this.cityTarget.value = ''
      this.cityTarget.setAttribute('aria-invalid', 'false')
    }
    if (this.hasStateTarget) {
      this.stateTarget.value = ''
      this.stateTarget.setAttribute('aria-invalid', 'false')
    }

    // Do not change the radio selection — preserve the user's selected mode
  }

  _announceStatus(message) {
    const statusEl = document.getElementById('weather-status')
    if (!statusEl) return
    // Clear then set text to ensure assistive tech notices changes even if identical text
    statusEl.textContent = ''
    setTimeout(() => { statusEl.textContent = message }, 50)
  }
}
