export const useAuth = () => {
  const isLoggedIn = useState<boolean>('isLoggedIn', () => false)
  const router = useRouter()

  const login = () => {
    isLoggedIn.value = true
    router.push('/dashboard/environments')
  }

  const logout = () => {
    isLoggedIn.value = false
    router.push('/')
  }

  return { isLoggedIn, login, logout }
}